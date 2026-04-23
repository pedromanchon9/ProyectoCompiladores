#include "func_semantico.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

// --- Variables que vienen de Flex/Bison ---
extern int yylineno;
extern int errores;

// --- Definición de Variables Globales del Compilador ---
Lista l;                    //lista de simbolos btw

char registros[10];
Lista l_memoria = NULL;    
int id_label = 1;
int cont_str = 1;
int nivel_actual = 0;       //Para comprobar el nivel (local o global)
char* func_actual = NULL;   //Para comprobar el nombre de la función actual para evitar la redeclaración por función unicamente :P
int tipo_actual = 0;
int tipo_retorno = 0;
int ex_return = 0;
int decl_param = 0;
int cont_arg = 0;


// --- Funciones de Semántica y Ámbitos ---


void declarar_id( char *id, Tipo t){

    if (strcmp(id, "main") == 0 && t != FUNCION) {
        printf("Error semantico en linea %d: 'main' esta reservado para la funcion principal y no puede usarse como variable o constante.\n", yylineno);
        errores++;
        return; // Salimos inmediatamente para no añadirla a la tabla de símbolos
    }

    PosicionLista p = buscaLS(l,id);
    if(p != finalLS(l)){
            Simbolo enc = recuperaLS(l, p);   //por evitar hacer la función 2 veces vaya-
            if (enc.tipo == FUNCION) {
                errores++;
                printf("Error semantico en linea %d: '%s' ya existe como funcion.\n", yylineno, id);
                return;
            }

            if(enc.nivel == nivel_actual) {
                errores++;
                printf("Errores en linea %d: %s redeclarador \n", yylineno, id);
                return;
            } 
    }
        Simbolo s;
        s.nombre = id;
        s.tipo = t;
        s.valor = 0;
        
    if (t == FUNCION) {s.nivel = 0; s.pert_fun = NULL;}
    else {
        
        s.nivel = nivel_actual;
        
         if (s.nivel > 0) { 
            s.pert_fun = strdup(func_actual);
        } else {   
            s.pert_fun = NULL;
        }
    }

    insertaLS(l,finalLS(l),s);
    if(t != FUNCION) {registrar_en_memoria(s);}
}  

void verificar_id(char *id) {
    PosicionLista p = buscaLS(l, id);
    if(p == finalLS(l)) {
        printf("Errores en linea %d: variable '%s' no declarada\n" , yylineno, id);
        errores++;
    }
}

void verificar_funcion(char *id) {
    PosicionLista p = buscaLS(l, id);
    if(p == finalLS(l)) {
        printf("Errores en linea %d: función '%s' no declarada \n" , yylineno, id);
        errores++;
    }else if(recuperaLS(l,p).tipo != FUNCION){
        printf("Errores en linea %d:'%s' no es una función \n" , yylineno, id);
        errores++;
    }
}

char* obtener_etiqueta_mips(char* id){
    PosicionLista p = buscaLS(l, id);

    /*
    
    Esto ayuda al filtrado de etiquetas por nivel es decir saber identificar 
    entre las variables locales y globales lo que quiere decir es que gracias
    esta modificación de etiquetas podemos diferenciar entre niveles, esta función
    sustituira a al asprintf en las funciones sw, lw y read ya que si no lo hicieramos
    siempre modificariamos la local, ya que no habria forma de identificarlas en MIPS.    
    
    */

    if (p == finalLS(l)) {
        errores++;
        return strdup(id); 
    }
    
    Simbolo s = recuperaLS(l, p);
    char *etiqueta;
    
    if (s.nivel == 0) {
        // nivel global: _nombre (ej: "_a")
        asprintf(&etiqueta, "_%s", s.nombre);
    } else {
        // nivel local: _Lnivel_nombre (ej: "_main_a")
        asprintf(&etiqueta, "_%s_%s", s.pert_fun, s.nombre);
    }

    return etiqueta;
};

void imprimir_datos(Lista lista) {
    printf("##################\n# Seccion de datos\n.data\n\n");
    if (l_memoria == NULL) return;

    PosicionLista p = inicioLS(lista);
    while (p != finalLS(lista)) {
        Simbolo s = recuperaLS(lista, p);
        if (s.tipo == CADENA) {
            printf("$str%d:\n\t.asciiz %s\n", s.valor, s.nombre);
        }
        p = siguienteLS(lista, p);
    }

    if (l_memoria == NULL)  {return;}
    p = inicioLS(l_memoria);
    while (p != finalLS(l_memoria)) {
        Simbolo s = recuperaLS(l_memoria, p);
        if (s.tipo == CONSTANTE || s.tipo == VARIABLE) {
            if (s.nivel == 0) {
                 printf("_%s:\n\t.word 0\n", s.nombre);
            } else {
                 printf("_%s_%s:\n\t.word 0\n", s.pert_fun, s.nombre);
            }
        }
        p = siguienteLS(l_memoria, p);
    }
    printf("\n");
}

void entrar_nivel(char* id) {
    func_actual = strdup(id);
    nivel_actual++;
};

void salir_nivel() {
    free(func_actual);
    func_actual = NULL;
    liberar_nivel(l, nivel_actual);
    nivel_actual--;
};



/****************************************************************************************/


// --- Funciones Auxiliares ---

char *nueva_etiqueta() {
    char *nom;
    asprintf(&nom, "$l%d", id_label++); // Cambiado de "label%d" a "$l%d"
    return nom;
};

void inicializar_reg(){

    memset(registros,0,sizeof(char)*10);
};

char *obtener_reg(){
    for(int i = 0; i < 10; i++){
        if (registros[i] == 0){
            // $ti
            char *reg;
            asprintf(&reg, "$t%d", i);
            registros[i] = 1;
            return reg;
        }
    }
    printf("Error fatal; regustros agotados!\n");
    exit(1);
};

void liberar_reg(char *reg){
    //reg = %ti
    assert(reg[0]=='$');
    assert(reg[1]=='t');
    int i = reg[2] - '0';
    assert(i <= 9);
    assert(i >= 0);
    registros[i] = 0;
}

int generar_str(char *str){
    Simbolo s;
    s.nombre = str;
    s.tipo = CADENA;
    s.valor = cont_str;
    s.nivel = 0;        
    s.pert_fun = NULL;   
    insertaLS(l,finalLS(l), s);
    return cont_str++;
}

void registrar_en_memoria(Simbolo s) {
    if (l_memoria == NULL) l_memoria = creaLS();
    PosicionLista p = inicioLS(l_memoria);
    while (p != finalLS(l_memoria)) {
        Simbolo existente = recuperaLS(l_memoria, p);
        if (strcmp(existente.nombre, s.nombre) == 0 && 
            ((s.nivel == 0 && existente.nivel == 0) || 
             (s.nivel > 0 && strcmp(existente.pert_fun, s.pert_fun) == 0))) {
            return; 
        }
        p = siguienteLS(l_memoria, p);
    }
    insertaLS(l_memoria, finalLS(l_memoria), s);
};

/****************************************************************************************/


// --- Funciones de Generación de Código (ListaC) ---

ListaC declarar_funcion( char *id, ListaC cuerpo){

    declarar_id(id, FUNCION);

    ListaC codigo = generar_etiqueta(id);
    
    //generar espacio en la pila para almacenar el valor final de la función
    concatenaLC(codigo, llamada_addi("$sp", "$sp", "-4"));
    concatenaLC(codigo, llamada_sw("$ra", "0($sp)"));

    //cuerpo de la función
    concatenaLC(codigo, cuerpo);
    liberaLC(cuerpo);

    return codigo;
}

ListaC generar_etiqueta(char *etiqueta) {
    ListaC codigo = creaLC();
    Operacion o;
    
    char *marca;
    asprintf(&marca, "%s:", etiqueta);
    
    o.op = marca;     
    o.res = NULL;
    o.arg1 = NULL;
    o.arg2 = NULL;
    
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
};

ListaC concatenar_funciones(ListaC lista, ListaC funcion){

    concatenaLC(lista, funcion);
    liberaLC(funcion);

    return lista;
};


// sujetas a camibios

ListaC declarar_parametro(char *id, Tipo t){
    if(decl_param>=4){
        errores++;
        printf("Error en la linea %d , La función %s excede el límite de parametros, El limite de parametros establecido es de 4 ", yylineno, func_actual); 
        return creaLC();    //al exceder el limite de parametros no quedan registros $a por tanto creamos una lista de código por tener algo retornar
    }

    declarar_id(id, t);

    ListaC codigo = creaLC();
    char* a_reg;
    asprintf(&a_reg, "$a%d", decl_param);

    concatenaLC(codigo, llamada_sw(a_reg, obtener_etiqueta_mips(id)));

    decl_param++;
    return codigo;

};

ListaC pasar_argumento(ListaC expr){
     if(cont_arg>=4){
        errores++;
        printf("Error en la linea %d , La función %s excede el límite de parametros, El limite de argumentos establecido es de 4 ", yylineno, func_actual); 
        return expr;    //al exceder el limite de parametros no quedan registros $a por tanto creamos una lista de código por tener algo retornar
    }

    ListaC codigo = creaLC();
    char* a_reg;
    asprintf(&a_reg, "$a%d", cont_arg);
    concatenaLC(codigo, expr);

    concatenaLC(codigo, expresion_move(a_reg, recuperaResLC(expr)));
    liberar_reg(recuperaResLC(expr));

    cont_arg++;
    return codigo;
};

// sujetas a cambios


ListaC generar_salto(char *etiqueta) {
    ListaC codigo = creaLC();
    Operacion o;
    
    o.op = "b";          
    o.res = etiqueta;   
    o.arg1 = NULL;
    o.arg2 = NULL;
    
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
}

ListaC generar_jr(char *registro){
    ListaC codigo = creaLC();
    Operacion o;

    o.op = "jr";
    o.res = registro;
    o.arg1 = NULL;
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    return codigo;
}

ListaC expresion_return(ListaC expr){
    ListaC codigo = creaLC();

    ex_return =1;

    if(tipo_retorno != 0 && expr == NULL){
        errores++;
        printf("Error en la linea %d, debe existir un valor de retorno para la función %s, ", yylineno, func_actual);
    }

    if(tipo_retorno == 0 && expr != NULL){
        errores++;
        printf("Error en la linea %d, la función %s es declarada void no puede retornar un valor, ", yylineno, func_actual);
    }

    // Aqui lo que hacemos es guardar en el registro $v0 el valor de la 
    //expresión a retornar es decir si expresion es 4 guardamos en el registro $v0 4
    if (expr != NULL) {
        concatenaLC(codigo, expr);
        concatenaLC(codigo, expresion_move("$v0", recuperaResLC(expr)));
        liberar_reg(recuperaResLC(expr)); 
        liberaLC(expr);     //liberamos el registro que guardaba expr ya que no nos va a hacer más falta
    }

    //En la función declarar función es donde modificamos el valor de sp a -4 para poder guardar nuestro $ra
    /*debido a que podemos llamar a multiples funciones lo que haremos sera 
    almacenar los valores de dichas funciones en el registro $sp 
    Para ello usaremos la instrucción lw y posteriormente llamaremos a una función
    add para aumentar en 4 ya que   solo declaramos un tipo entero en nuestro compilador*/
    

    concatenaLC(codigo, llamada_lw("$ra", "0($sp)"));
    concatenaLC(codigo, llamada_addi("$sp", "$sp", "4"));
    concatenaLC(codigo, generar_jr("$ra"));

    return codigo;

};

ListaC generar_jal(char *etiqueta){
    ListaC codigo = creaLC();
    Operacion o;

    o.op = "jal";
    o.res = etiqueta;
    o.arg1 = NULL;
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    return codigo;

};

ListaC expresion_llamada_func(char *id, ListaC args) {
    verificar_funcion(id); //Comprbamos que es una función primero

    ListaC codigo = creaLC();

    if(args != NULL){

        concatenaLC(codigo, args);
        liberaLC(args);
    }

    concatenaLC(codigo, generar_jal(id));

    char *reg_res = obtener_reg();
    concatenaLC(codigo,expresion_move(reg_res, "$v0"));
    guardaResLC(codigo, reg_res);

    return codigo;

};

ListaC generar_bz(ListaC expr, char *etiqueta , char *nombre) {
    ListaC codigo = expr;
    Operacion o;
    o.op = nombre;
    o.res = recuperaResLC(expr);
    o.arg1 = strdup(etiqueta);
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    liberar_reg(o.res);

    return codigo;
}

ListaC statment_if(ListaC expr, ListaC cuerpo){
    char* etiqueta_fin = nueva_etiqueta();
    ListaC codigo = expr;

    generar_bz(expr, etiqueta_fin,"beqz");

    concatenaLC(codigo, cuerpo);
    liberaLC(cuerpo);

    concatenaLC(codigo, generar_etiqueta(etiqueta_fin));

    return codigo;
};

ListaC statment_if_else(ListaC expr, ListaC cuerpo_if, ListaC cuerpo_else){
    char* etiqueta_fin = nueva_etiqueta();
    char* etiqueta_else = nueva_etiqueta();
    ListaC codigo = expr;

    generar_bz(expr, etiqueta_else,"beqz");

    concatenaLC(codigo, cuerpo_if);
    liberaLC(cuerpo_if);

    concatenaLC(codigo, generar_salto(etiqueta_fin));

    concatenaLC(codigo, generar_etiqueta(etiqueta_else));

    concatenaLC(codigo, cuerpo_else);
    liberaLC(cuerpo_else);

    concatenaLC(codigo, generar_etiqueta(etiqueta_fin));

    return codigo;
};

ListaC statment_while(ListaC expr, ListaC cuerpo_while) {

    char* etiqueta_fin = nueva_etiqueta();
    char* etiqueta_inicio = nueva_etiqueta();
    
    ListaC codigo = creaLC();
    concatenaLC(codigo, generar_etiqueta(etiqueta_inicio));


    ListaC condicion = generar_bz(expr, etiqueta_fin,"beqz");
    concatenaLC(codigo, condicion);
    liberaLC(condicion);                      //condición

    concatenaLC(codigo, cuerpo_while);
    liberaLC(cuerpo_while);                                     //adoptamos el codigo interno del while

    concatenaLC(codigo, generar_salto(etiqueta_inicio));        //j inicio
    concatenaLC(codigo, generar_etiqueta(etiqueta_fin));        //etiqueta de fin

    return codigo;

};

ListaC generar_llam_sys() {
    ListaC codigo = creaLC();
    Operacion o;
    
    o.op = "syscall";
    o.res =  NULL;
    o.arg1 = NULL;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
};

ListaC generar_print_expresion(ListaC expr) {
    ListaC codigo = expr;
    Operacion o;

    char* registro_resultado = strdup(recuperaResLC(expr)); 
    concatenaLC(codigo,expresion_move("$a0", registro_resultado));
    liberar_reg(registro_resultado);

    concatenaLC(codigo, expresion_num("$v0","1"));
    
    concatenaLC(codigo, generar_llam_sys());
    
    return codigo;
};

ListaC generar_print_str(int id) {
    ListaC codigo = creaLC();
    Operacion o;
    char *etiqueta;
    
    asprintf(&etiqueta, "$str%d", id); 

    // la $a0 etiqueta
    concatenaLC(codigo, expresion_etiq("$a0", etiqueta));

    // li $v0, 4
    concatenaLC(codigo, expresion_num("$v0", "4"));

    // syscall
    concatenaLC(codigo, generar_llam_sys());
    return codigo;
};

ListaC generar_read_id(char *id) {

    verificar_id(id);

    ListaC codigo = creaLC();
    Operacion o;

    concatenaLC(codigo, expresion_num("$v0", "5"));

    concatenaLC(codigo, generar_llam_sys());

    o.op = "sw";
    o.res = "$v0";
    char* etiqueta_nivel = obtener_etiqueta_mips(id);
    o.arg1 = etiqueta_nivel;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);

    return codigo;

};

ListaC guardar_reg(char *id, ListaC expr) {
    ListaC codigo = expr;
    Operacion o;
    o.op = "sw";
    o.res = NULL;
    o.arg1 = recuperaResLC(expr);
    char* etiqueta_nivel = obtener_etiqueta_mips(id);            //recuperamos reg
    o.arg2 = etiqueta_nivel;                                     //preparamos mem
    insertaLC(codigo, finalLC(codigo), o);                       //guardamos el valor
    liberar_reg(o.arg1);                                         //liberamos registro libre
    return codigo;
}

ListaC expresion_num(char *reg_des, char *valor) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "li";
    o.res = reg_des;
    o.arg1 = valor;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);

    if (reg_des[0] == '$' && reg_des[1] == 't') {
        guardaResLC(codigo, reg_des);
    }

    return codigo;
}

ListaC expresion_etiq(char *reg_des, char *etiqueta) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "la";
    o.res = reg_des;
    o.arg1 = etiqueta;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
}

ListaC expresion_id(char *id) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "lw";
    o.res = obtener_reg();
    char* etiqueta_nivel = obtener_etiqueta_mips(id);
    o.arg1 = etiqueta_nivel;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    guardaResLC(codigo, o.res);
    return codigo;
}

// Revisar la optimización y repetición de código

ListaC llamada_lw(char* reg1, char* reg2) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "lw";
    o.res = reg1;
    o.arg1 = reg2;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    guardaResLC(codigo, o.res);
    return codigo;
};

ListaC llamada_sw(char* reg1, char* reg2) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "sw";
    o.res = reg1;
    o.arg1 = reg2;
    o.arg2 = NULL;
    insertaLC(codigo, finalLC(codigo), o);
    guardaResLC(codigo, o.res);
    return codigo;
}

ListaC llamada_addi(char* reg1, char* reg2, char* valor) {
    ListaC codigo = creaLC();
    Operacion o;
    o.op = "addi";
    o.res = reg1;
    o.arg1 = reg2;
    o.arg2 = valor;
    insertaLC(codigo, finalLC(codigo), o);
    guardaResLC(codigo, o.res);
    return codigo;
};

//funciones abiertas a posibles cambios

ListaC expresion_move(char *reg_des, char *reg_origen) {     //move

    ListaC codigo = creaLC();
    Operacion o; 
    o.op = "move";
    o.res = reg_des;
    o.arg1 = reg_origen;
    o.arg2 = NULL;

    insertaLC(codigo, finalLC(codigo), o);

    return codigo;
}

ListaC expresion_neg(ListaC expr) {
    ListaC codigo = expr;
    Operacion o;
    o.op = "neg";
    o.res = recuperaResLC(expr);   //reescribimos el registro
    o.arg1 = recuperaResLC(expr);  //el registro a negar
    o.arg2 = NULL;
    
    insertaLC(codigo, finalLC(codigo), o);
    return codigo;
} 

ListaC expresion_bin(ListaC expr1, ListaC expr2, char *op) {
    ListaC codigo = expr1;
    Operacion o;
    if (strcmp(op, "add") == 0 && longitudLC(expr2) == 1) {
        
        o.op = "addi";
        o.res = o.arg1 = recuperaResLC(expr1);
        o.arg2 = recuperaLC(expr2, inicioLC(expr2)).arg1; 
        
        insertaLC(codigo, finalLC(codigo), o);
        liberaLC(expr2);
        return codigo;
    }
    concatenaLC(codigo, expr2);
    o.op = op;
    o.res = o.arg1 = recuperaResLC(expr1);
    o.arg2 = recuperaResLC(expr2);
    insertaLC(codigo, finalLC(codigo), o);
    liberar_reg(o.arg2);
    liberaLC(expr2);
    return codigo;

}

ListaC fin_programa(){
    ListaC codigo = creaLC();
    Operacion o;
    concatenaLC(codigo, expresion_num("$v0","10"));
    concatenaLC(codigo, generar_llam_sys());

    return codigo;
};

void imprimir_lc(ListaC codigo1){
    PosicionListaC p = inicioLC(codigo1);
    while(p != finalLC(codigo1)){
        Operacion oper = recuperaLC(codigo1,p);
        if(oper.op[strlen(oper.op)-1] == ':'){
        printf("%s\n", oper.op);
        }else{
            printf("\t%s ", oper.op);
            int primero_impreso = 0;

            if(oper.res) {
                printf(" %s", oper.res);
                primero_impreso = 1;
            };

            if(oper.arg1) {
                if (primero_impreso) printf(","); // Añadimos coma si ya hay algo antes
                printf(" %s", oper.arg1);
                primero_impreso = 1;
            }

            if (oper.arg2) {
                if (primero_impreso) printf(","); // Añadimos coma si ya hay algo antes
                printf(" %s", oper.arg2);
            }
                printf("\n");
            }
        p = siguienteLC(codigo1,p);
    }
};

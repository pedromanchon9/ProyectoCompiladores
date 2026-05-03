#ifndef __FUNC_SEMANTICO_H__
#define __FUNC_SEMANTICO_H__

#include "listaSimbolos.h"
#include "listaCodigo.h"
#include <stdbool.h>

// --- Variables Globales Exportadas ---
extern Lista l;
extern int nivel_actual;
extern char* func_actual;
extern int tipo_actual;
extern int tipo_retorno;
extern int ex_return;
extern int decl_param;          // para los declarados
extern int cont_arg;            // para los introducidos

// --- Funciones de Semántica y Ámbitos ---
void declarar_id(char *id, Tipo t);
void verificar_id(char *id);
void verificar_asignacion(char *id);
void verificar_funcion(char *id);
char* obtener_etiqueta_mips(char *id);
void imprimir_datos(Lista lista);
void entrar_nivel();
void salir_nivel();

// --- Funciones Auxiliares ---
char *nueva_etiqueta();
void inicializar_reg();
char *obtener_reg();
void registrar_en_memoria(Simbolo s);
void liberar_reg(char *reg);
int generar_str(char *str);

// --- Funciones de Generación de Código (ListaC) ---
ListaC declarar_funcion(char *id, ListaC cuerpo);
ListaC generar_etiqueta(char *etiqueta);
ListaC concatenar_funciones(ListaC lista, ListaC funcion);

// sujetas a camibios

ListaC declarar_parametro(char *id, Tipo t);
ListaC pasar_argumento(ListaC expr);

// sujetas a cambios

ListaC generar_salto(char *etiqueta);
ListaC generar_jr(char *registro);
ListaC expresion_return(ListaC expr);
ListaC generar_jal(char *etiqueta);

//modificada para los parametros
ListaC expresion_llamada_func(char *id, ListaC args);
/************************************************/

ListaC generar_bz(ListaC expr, char *etiqueta , char *nombre);
ListaC statment_if(ListaC expr, ListaC cuerpo);
ListaC statment_if_else(ListaC expr, ListaC cuerpo_if, ListaC cuerpo_else);
ListaC statment_while(ListaC expr, ListaC cuerpo);
ListaC statment_do_while(ListaC expr, ListaC cuerpo);
ListaC generar_llam_sys();
ListaC generar_print_expresion(ListaC expr);
ListaC generar_print_str(int id);
ListaC generar_read_id(char *id);
ListaC guardar_reg(char *id, ListaC expr);
ListaC expresion_num(char *reg_des, char *valor);
ListaC expresion_etiq(char *reg_des, char *etiqueta);
ListaC expresion_id(char *id);

//pc
ListaC llamada_lw(char* reg1, char* reg2);
ListaC llamada_sw(char* reg1, char* reg2);
ListaC llamada_addi(char* reg1, char* reg2, char* valor);
//pc

ListaC expresion_move(char *reg_des, char *reg_origen);
ListaC expresion_neg(ListaC expr);
ListaC expresion_bin(ListaC expr1, ListaC expr2, char *op);
ListaC fin_programa();
void imprimir_lc(ListaC codigo1);

#endif
#include "listaSimbolos.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>

struct PosicionListaRep {
  Simbolo dato;
  struct PosicionListaRep *sig;
};

struct ListaRep {
  PosicionLista cabecera;
  PosicionLista ultimo;
  int n;
};

typedef struct PosicionListaRep *NodoPtr;

Lista creaLS() {
  Lista nueva = malloc(sizeof(struct ListaRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  return nueva;
}

void liberaLS(Lista lista) {
  while (lista->cabecera != NULL) {
    NodoPtr borrar = lista->cabecera;
    lista->cabecera = borrar->sig;
    free(borrar);
  }
  free(lista);
}

void insertaLS(Lista lista, PosicionLista p, Simbolo s) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaRep));
  nuevo->dato = s;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (lista->ultimo == p) {
    lista->ultimo = nuevo;
  }
  (lista->n)++;
}

void suprimeLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  NodoPtr borrar = p->sig;
  p->sig = borrar->sig;
  if (lista->ultimo == borrar) {
    lista->ultimo = p;
  }
  free(borrar);
  (lista->n)--;
}

Simbolo recuperaLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig->dato;
}

/*

  Modificación de la función busca ya que en nuestro miniC usaremos una prioridad a nivel local es decir 
  si existen varias funciones con el mismo nombre a distintos niveles
  usaremos el valor del nivel local más cercano, en vez del global.

*/

PosicionLista buscaLS(Lista lista, char *nombre) {
  NodoPtr aux = lista->cabecera;
  PosicionLista enc = lista->ultimo;
  int max_nivel = -1;
  while (aux->sig != NULL){
    if(strcmp(aux->sig->dato.nombre,nombre) == 0) {
        if(aux->sig->dato.nivel > max_nivel){
          max_nivel = aux->sig->dato.nivel;
          enc = aux;
      }
    }
    aux = aux->sig;
  }
  return enc;
}

void asignaLS(Lista lista, PosicionLista p, Simbolo s) {
  assert(p != lista->ultimo);
  p->sig->dato = s;
}

int longitudLS(Lista lista) {
  return lista->n;
}

PosicionLista inicioLS(Lista lista) {
  return lista->cabecera;
}

PosicionLista finalLS(Lista lista) {
  return lista->ultimo;
}

PosicionLista siguienteLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig;
}

/*
  Esta función se implemento para la liberación de variables a ciertos nivels
  es decir en caso de salir de una función liberar las variables declaradas 
  para evitar un almacenamiento inncesario de variables en el sistema,
  esta función se usa al salir de una llamada de función (tambien ayuda a la multiple
  declaración de variables a cierto nivel es decir poder llamar en dos funciones diferentes 
  a una variable igual)
*/

void liberar_nivel(Lista lista, int nivel) {
    PosicionLista p = inicioLS(lista);
    while (p != finalLS(lista)) {
        if (recuperaLS(lista, p).nivel== nivel) {
            suprimeLS(lista, p); 
        } else {
            p = siguienteLS(lista, p);
        }
    }
}
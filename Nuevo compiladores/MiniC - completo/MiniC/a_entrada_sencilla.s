##################
# Seccion de datos
.data

$str1:
	.asciiz "--- INICIO DE LA PRUEBA BASICA ---\n"
$str2:
	.asciiz "Introduce un numero para el contador: "
$str3:
	.asciiz "Has introducido un numero distinto de cero.\n"
$str4:
	.asciiz "Has introducido un cero. Ajustando valor...\n"
$str5:
	.asciiz "El valor del calculo es: "
$str6:
	.asciiz "\n"
$str7:
	.asciiz "Iniciando secuencia de conteo hasta el limite...\n"
$str8:
	.asciiz "Ejecutando bucle... contador = "
$str9:
	.asciiz "\n"
$str10:
	.asciiz "--- FIN DEL PROGRAMA ---\n"
_main_limite:
	.word 0
_main_contador:
	.word 0
_main_calculo:
	.word 0


###################
#Seccion de codigo
.text
.globl main
 j main

main:
	addi  $sp, $sp, -4
	sw  $ra, 0($sp)
	li  $t0, 5
	sw  $t0, _main_limite
	la  $a0, $str1
	li  $v0, 4
	syscall 
	la  $a0, $str2
	li  $v0, 4
	syscall 
	li  $v0, 5
	syscall 
	sw  $v0, _main_contador
	lw  $t0, _main_contador
	beqz  $t0, $l2
	la  $a0, $str3
	li  $v0, 4
	syscall 
	lw  $t1, _main_contador
	li  $t2, 2
	mul  $t1, $t1, $t2
	sw  $t1, _main_calculo
	b  $l1
$l2:
	la  $a0, $str4
	li  $v0, 4
	syscall 
	li  $t1, 1
	sw  $t1, _main_contador
	lw  $t1, _main_contador
	addi  $t1, $t1, 10
	sw  $t1, _main_calculo
$l1:
	la  $a0, $str5
	li  $v0, 4
	syscall 
	lw  $t0, _main_calculo
	move  $a0, $t0
	li  $v0, 1
	syscall 
	la  $a0, $str6
	li  $v0, 4
	syscall 
	la  $a0, $str7
	li  $v0, 4
	syscall 
$l4:
	lw  $t0, _main_limite
	lw  $t1, _main_contador
	sub  $t0, $t0, $t1
	beqz  $t0, $l3
	la  $a0, $str8
	li  $v0, 4
	syscall 
	lw  $t1, _main_contador
	move  $a0, $t1
	li  $v0, 1
	syscall 
	la  $a0, $str9
	li  $v0, 4
	syscall 
	lw  $t1, _main_contador
	addi  $t1, $t1, 1
	sw  $t1, _main_contador
	b  $l4
$l3:
	la  $a0, $str10
	li  $v0, 4
	syscall 

# Fin del programa
	li  $v0, 10
	syscall 
# Compilacion termina con 0 errores

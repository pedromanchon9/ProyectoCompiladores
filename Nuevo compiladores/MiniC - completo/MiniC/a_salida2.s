##################
# Seccion de datos
.data

$str1:
	.asciiz "restantes \n"
$str2:
	.asciiz "Resultado: "
$str3:
	.asciiz "\n"
_leer_fe:
	.word 0
_main_a:
	.word 0
_main_res:
	.word 0
_main_ler:
	.word 0


###################
#Seccion de codigo
.text
.globl main
 j main

leer:
	addi  $sp, $sp, -4
	sw  $ra, 0($sp)
	sw  $a0, _leer_fe
$l2:
	lw  $t0, _leer_fe
	beqz  $t0, $l1
	lw  $t1, _leer_fe
	move  $a0, $t1
	li  $v0, 1
	syscall 
	la  $a0, $str1
	li  $v0, 4
	syscall 
	lw  $t1, _leer_fe
	li  $t2, 1
	sub  $t1, $t1, $t2
	sw  $t1, _leer_fe
	b  $l2
$l1:
	lw  $t0, _leer_fe
	addi  $t0, $t0, 5
	sw  $t0, _leer_fe
	lw  $t0, _leer_fe
	move  $v0, $t0
	lw  $ra, 0($sp)
	addi  $sp, $sp, 4
	jr  $ra
	lw  $ra, 0($sp)
	addi  $sp, $sp, 4
	jr  $ra
main:
	addi  $sp, $sp, -4
	sw  $ra, 0($sp)
	li  $t0, 20
	sw  $t0, _main_a
	li  $t0, 10
	sw  $t0, _main_res
	lw  $t0, _main_res
	move  $a0, $t0
	jal  leer
	move  $t0, $v0
	sw  $t0, _main_ler
	lw  $t0, _main_ler
	lw  $t1, _main_a
	add  $t0, $t0, $t1
	sw  $t0, _main_ler
	la  $a0, $str2
	li  $v0, 4
	syscall 
	lw  $t0, _main_ler
	move  $a0, $t0
	li  $v0, 1
	syscall 
	la  $a0, $str3
	li  $v0, 4
	syscall 

# Fin del programa
	li  $v0, 10
	syscall 
# Compilacion termina con 0 errores

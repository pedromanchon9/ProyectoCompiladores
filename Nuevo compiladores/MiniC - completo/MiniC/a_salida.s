##################
# Seccion de datos
.data

$str1:
	.asciiz "Inicio del programa\n"
$str2:
	.asciiz "a"
$str3:
	.asciiz "\n"
$str4:
	.asciiz "No a y b\n"
$str5:
	.asciiz "c = "
$str6:
	.asciiz "\n"
$str7:
	.asciiz "Final"
$str8:
	.asciiz "\n"
_leer_fe:
	.word 0
_leer_moscas:
	.word 0
_leer_red:
	.word 0
_leer_g:
	.word 0
_leer_a3:
	.word 0
_mega_na:
	.word 0
_mega_f:
	.word 0
_mega_gue:
	.word 0
_mega_man:
	.word 0
_mega_a:
	.word 0
_mega_bern:
	.word 0
_main_a:
	.word 0
_main_b:
	.word 0
_main_c:
	.word 0
_main_alb:
	.word 0
_main_tar:
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
	sw  $a1, _leer_moscas
	sw  $a2, _leer_red
	li  $t0, 0
	sw  $t0, _leer_g
	li  $t0, 3
	sw  $t0, _leer_a3
	lw  $t0, _leer_red
	lw  $t1, _leer_moscas
	mul  $t0, $t0, $t1
	sw  $t0, _leer_fe
	lw  $t0, _leer_moscas
	move  $v0, $t0
	lw  $ra, 0($sp)
	addi  $sp, $sp, 4
	jr  $ra
	lw  $ra, 0($sp)
	addi  $sp, $sp, 4
	jr  $ra
mega:
	addi  $sp, $sp, -4
	sw  $ra, 0($sp)
	sw  $a0, _mega_na
	sw  $a1, _mega_f
	li  $t0, 0
	sw  $t0, _mega_gue
	li  $t0, 2
	sw  $t0, _mega_man
	li  $t0, 4
	sw  $t0, _mega_a
	li  $t0, 2
	sw  $t0, _mega_bern
	li  $t0, 4
	li  $t1, 2
	mul  $t0, $t0, $t1
	sw  $t0, _mega_man
	lw  $t0, _mega_gue
	beqz  $t0, $l3
	lw  $t1, _mega_man
	beqz  $t1, $l2
	lw  $t2, _mega_gue
	li  $t3, 3
	mul  $t2, $t2, $t3
	sw  $t2, _mega_a
	b  $l1
$l2:
	li  $t2, 3
	li  $t3, 2
	mul  $t2, $t2, $t3
	sw  $t2, _mega_man
$l1:
$l3:
$l4:
	lw  $t0, _mega_man
	addi  $t0, $t0, 1
	sw  $t0, _mega_man
	lw  $t0, _mega_man
	beqz  $t0, $l4
	lw  $ra, 0($sp)
	addi  $sp, $sp, 4
	jr  $ra
main:
	addi  $sp, $sp, -4
	sw  $ra, 0($sp)
	li  $t0, 0
	sw  $t0, _main_a
	li  $t0, 0
	sw  $t0, _main_b
	la  $a0, $str1
	li  $v0, 4
	syscall 
	li  $t0, 5
	addi  $t0, $t0, 2
	li  $t1, 2
	sub  $t0, $t0, $t1
	sw  $t0, _main_c
	lw  $t0, _main_c
	move  $a0, $t0
	lw  $t0, _main_b
	move  $a1, $t0
	lw  $t0, _main_a
	move  $a2, $t0
	jal  leer
	move  $t0, $v0
	sw  $t0, _main_alb
	li  $t0, 5
	sw  $t0, _main_tar
	lw  $t0, _main_a
	beqz  $t0, $l10
	la  $a0, $str2
	li  $v0, 4
	syscall 
	la  $a0, $str3
	li  $v0, 4
	syscall 
	b  $l9
$l10:
	lw  $t1, _main_b
	beqz  $t1, $l8
	la  $a0, $str4
	li  $v0, 4
	syscall 
	b  $l7
$l8:
$l6:
	lw  $t2, _main_c
	beqz  $t2, $l5
	la  $a0, $str5
	li  $v0, 4
	syscall 
	lw  $t3, _main_c
	move  $a0, $t3
	li  $v0, 1
	syscall 
	la  $a0, $str6
	li  $v0, 4
	syscall 
	lw  $t3, _main_a
	move  $a0, $t3
	lw  $t3, _main_b
	move  $a1, $t3
	lw  $t3, _main_alb
	move  $a2, $t3
	jal  leer
	move  $t3, $v0
	sw  $t3, _main_tar
	lw  $t3, _main_tar
	move  $a0, $t3
	li  $v0, 1
	syscall 
	lw  $t3, _main_c
	li  $t4, 2
	sub  $t3, $t3, $t4
	addi  $t3, $t3, 1
	sw  $t3, _main_c
	b  $l6
$l5:
$l7:
$l9:
	la  $a0, $str7
	li  $v0, 4
	syscall 
	la  $a0, $str8
	li  $v0, 4
	syscall 

# Fin del programa
	li  $v0, 10
	syscall 
# Compilacion termina con 0 errores

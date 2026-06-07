; ============================================================================
; FILE        : main.asm
; PROJECT     : Stack-Based Infix-to-Postfix Expression Evaluator
; ENVIRONMENT : x86 MASM | Irvine32 | Visual Studio 2022 | Win32
; DESCRIPTION : Complete 4-module production-grade semester project.
;               Implements: Input/Validation/Tokenization (Module 1),
;               Infix-to-Postfix Shunting-Yard (Module 2),
;               Postfix Evaluator (Module 3),
;               Performance Analytics (Module 4).
; ============================================================================

INCLUDE Irvine32.inc

; ============================================================================
; COMPILE-TIME CONSTANTS
; ============================================================================
INPUT_BUFFER_SIZE    EQU 256
TOKEN_ARRAY_SIZE     EQU 128
OP_STACK_SIZE        EQU 64
EVAL_STACK_SIZE      EQU 64
MAX_DIGITS           EQU 10
TOKEN_TYPE_NUM       EQU 1
TOKEN_TYPE_OP        EQU 2
TOKEN_TYPE_LPAREN    EQU 3
TOKEN_TYPE_RPAREN    EQU 4
STACK_EMPTY_SENTINEL EQU 80000000h

; ============================================================================
; .data SEGMENT
; ============================================================================
.data

; ----------------------------------------------------------------------------
; MODULE 1 — Input / Validation / Tokenization strings & buffers
; ----------------------------------------------------------------------------
prompt_welcome      BYTE  "============================================", 0Dh, 0Ah
                    BYTE  "   Stack-Based Infix Expression Evaluator  ", 0Dh, 0Ah
                    BYTE  "   x86 Assembly  |  Irvine32  |  MASM      ", 0Dh, 0Ah
                    BYTE  "============================================", 0Dh, 0Ah, 0

prompt_enter_expr   BYTE  0Dh, 0Ah, "  Enter infix expression: ", 0
prompt_again        BYTE  0Dh, 0Ah, "  Evaluate another? (Y/N): ", 0
prompt_separator    BYTE  "--------------------------------------------", 0Dh, 0Ah, 0

infix_buffer        BYTE  INPUT_BUFFER_SIZE DUP(0)
infix_length        DWORD 0
paren_balance       SDWORD 0
validation_passed   BYTE  0
empty_input_flag    BYTE  0

err_empty_input     BYTE  "  [ERROR] No expression entered.", 0Dh, 0Ah, 0
err_invalid_char    BYTE  "  [ERROR] Invalid character in expression.", 0Dh, 0Ah
                    BYTE  "          Allowed: 0-9  + - * / ^  ( ) [ ] { }", 0Dh, 0Ah, 0
err_unbalanced_paren BYTE "  [ERROR] Unbalanced parentheses.", 0Dh, 0Ah, 0
err_consec_op       BYTE  "  [ERROR] Consecutive operators detected.", 0Dh, 0Ah, 0
err_leading_op      BYTE  "  [ERROR] Expression cannot begin with an operator.", 0Dh, 0Ah, 0
err_trailing_op     BYTE  "  [ERROR] Expression cannot end with an operator.", 0Dh, 0Ah, 0
err_empty_parens    BYTE  "  [ERROR] Empty brackets/parentheses detected.", 0Dh, 0Ah, 0

token_types         BYTE  TOKEN_ARRAY_SIZE DUP(0)
token_values        DWORD TOKEN_ARRAY_SIZE DUP(0)
token_count         DWORD 0

msg_tokens_label    BYTE  "  [OK]  Tokens found : ", 0

; ----------------------------------------------------------------------------
; MODULE 2 — Infix-to-Postfix strings & stacks
; ----------------------------------------------------------------------------
op_stack_chars      BYTE  OP_STACK_SIZE DUP(0)
op_stack_top        DWORD 0

postfix_types       BYTE  TOKEN_ARRAY_SIZE DUP(0)
postfix_values      DWORD TOKEN_ARRAY_SIZE DUP(0)
postfix_count       DWORD 0

; Precedence table: pairs of [ASCII_char, level], terminated by 0FFh
prec_table          BYTE  '^', 3, '*', 2, '/', 2, '+', 1, '-', 1, '(', 0, '[', 0, '{', 0, 0FFh

err_op_stack_ovf    BYTE  "  [ERROR] Operator stack overflow.", 0Dh, 0Ah, 0
err_mismatch_paren  BYTE  "  [ERROR] Mismatched parentheses in conversion.", 0Dh, 0Ah, 0

msg_postfix_label   BYTE  0Dh, 0Ah, "  Postfix Expression : ", 0
msg_space           BYTE  " ", 0

; ----------------------------------------------------------------------------
; MODULE 3 — Postfix Evaluator strings & stacks
; ----------------------------------------------------------------------------
eval_stack          SDWORD EVAL_STACK_SIZE DUP(0)
eval_stack_top      DWORD  0
eval_result         SDWORD 0
eval_result_valid   BYTE   0

div_dividend        SDWORD 0
div_divisor         SDWORD 0

err_div_zero        BYTE  "  [ERROR] Division by zero.", 0Dh, 0Ah, 0
err_eval_underflow  BYTE  "  [ERROR] Operand stack underflow.", 0Dh, 0Ah, 0
err_eval_overflow   BYTE  "  [ERROR] Operand stack overflow.", 0Dh, 0Ah, 0
err_leftover_ops    BYTE  "  [ERROR] Malformed expression (leftover operands).", 0Dh, 0Ah, 0

msg_result_label    BYTE  0Dh, 0Ah, "  Result             : ", 0
msg_negative_sign   BYTE  "-", 0

result_str_buffer   BYTE  16 DUP(0)

; ----------------------------------------------------------------------------
; MODULE 4 — Analytics variables & strings
; ----------------------------------------------------------------------------
time_start_ms         DWORD 0
time_end_ms           DWORD 0
time_elapsed_ms       DWORD 0

op_push_count         DWORD 0
op_pop_count          DWORD 0
eval_push_count       DWORD 0
eval_pop_count        DWORD 0
total_stack_ops       DWORD 0

token_proc_count      DWORD 0
validation_checks     DWORD 0
arithmetic_ops_done   DWORD 0

mem_input_used        DWORD 0
mem_token_used        DWORD 0
mem_postfix_used      DWORD 0
mem_op_stack_peak     DWORD 0
mem_eval_stack_peak   DWORD 0
mem_total_estimate    DWORD 0

op_stack_peak_depth   DWORD 0
eval_stack_peak_depth DWORD 0

msg_analytics_hdr   BYTE  0Dh, 0Ah
                    BYTE  "  ==========================================", 0Dh, 0Ah
                    BYTE  "       PERFORMANCE ANALYTICS REPORT        ", 0Dh, 0Ah
                    BYTE  "  ==========================================", 0Dh, 0Ah, 0
msg_time_ms         BYTE  "  Processing Time  (ms)    : ", 0
msg_op_pushes       BYTE  "  Operator Stack Pushes    : ", 0
msg_op_pops         BYTE  "  Operator Stack Pops      : ", 0
msg_eval_pushes     BYTE  "  Operand Stack Pushes     : ", 0
msg_eval_pops       BYTE  "  Operand Stack Pops       : ", 0
msg_total_s_ops     BYTE  "  Total Stack Operations   : ", 0
msg_tok_proc        BYTE  "  Tokens Processed         : ", 0
msg_arith_done      BYTE  "  Arithmetic Operations    : ", 0
msg_mem_est         BYTE  "  Est. Memory Used (bytes) : ", 0
msg_op_peak         BYTE  "  Op Stack Peak Depth      : ", 0
msg_eval_peak       BYTE  "  Eval Stack Peak Depth    : ", 0
msg_analytics_ftr   BYTE  "  ==========================================", 0Dh, 0Ah, 0
msg_goodbye         BYTE  0Dh, 0Ah
                    BYTE  "  Thank you for using Expression Evaluator.", 0Dh, 0Ah
                    BYTE  "  Goodbye.", 0Dh, 0Ah, 0

temp_dword          DWORD 0

; ============================================================================
; .code SEGMENT
; ============================================================================
.code

; ============================================================================
;  MODULE 1: INPUT, VALIDATION & TOKENIZATION
; ============================================================================

; ----------------------------------------------------------------------------
; PROC: ReadInfixInput
; Reads a string from console into infix_buffer using Irvine32 ReadString.
; OUT: EAX = bytes read, ZF=1 if empty
; ----------------------------------------------------------------------------
ReadInfixInput PROC
    PUSHAD
    mov  edx, OFFSET prompt_enter_expr
    call WriteString

    mov  edx, OFFSET infix_buffer
    mov  ecx, INPUT_BUFFER_SIZE - 1
    call ReadString                    ; EAX = bytes actually read

    mov  infix_length, eax

    mov  empty_input_flag, 0
    cmp  eax, 0
    jne  ReadInfixInput_done
    mov  empty_input_flag, 1

ReadInfixInput_done:
    POPAD
    mov  eax, infix_length
    cmp  eax, 0
    ret
ReadInfixInput ENDP

; ----------------------------------------------------------------------------
; PROC: MyIsOperator
; IN:  AL = character to test
; OUT: ZF=1 if AL is one of + - * / ^,  ZF=0 otherwise
; No registers modified except flags.
; ----------------------------------------------------------------------------
MyIsOperator PROC
    cmp  al, '+'
    je   MyIsOp_yes
    cmp  al, '-'
    je   MyIsOp_yes
    cmp  al, '*'
    je   MyIsOp_yes
    cmp  al, '/'
    je   MyIsOp_yes
    cmp  al, '^'
    je   MyIsOp_yes
    ; Not an operator — force ZF=0
    push eax
    mov  al, 1
    cmp  al, 0        ; ZF=0
    pop  eax
    ret
MyIsOp_yes:
    push eax
    xor  eax, eax
    cmp  eax, 0       ; ZF=1
    pop  eax
    ret
MyIsOperator ENDP

; ----------------------------------------------------------------------------
; PROC: MyIsDigit
; IN:  AL = character
; OUT: EBX = 1 if digit, EBX = 0 if not
; Uses EBX only.
; ----------------------------------------------------------------------------
MyIsDigit PROC
    xor  ebx, ebx
    cmp  al, '0'
    jb   MyIsDigit_no
    cmp  al, '9'
    ja   MyIsDigit_no
    mov  ebx, 1
    ret
MyIsDigit_no:
    ret
MyIsDigit ENDP

; ----------------------------------------------------------------------------
; PROC: MyIsValidChar
; IN:  AL = character to classify
; OUT: EBX = 1 if valid, 0 if invalid
; ----------------------------------------------------------------------------
MyIsValidChar PROC
    xor  ebx, ebx

    call MyIsDigit
    cmp  ebx, 1
    je   MyIsVC_yes

    cmp  al, '+'
    je   MyIsVC_yes
    cmp  al, '-'
    je   MyIsVC_yes
    cmp  al, '*'
    je   MyIsVC_yes
    cmp  al, '/'
    je   MyIsVC_yes
    cmp  al, '^'
    je   MyIsVC_yes
    cmp  al, '('
    je   MyIsVC_yes
    cmp  al, ')'
    je   MyIsVC_yes
    cmp  al, '['
    je   MyIsVC_yes
    cmp  al, ']'
    je   MyIsVC_yes
    cmp  al, '{'
    je   MyIsVC_yes
    cmp  al, '}'
    je   MyIsVC_yes
    cmp  al, ' '
    je   MyIsVC_yes
    cmp  al, 9
    je   MyIsVC_yes

    xor  ebx, ebx
    ret
MyIsVC_yes:
    mov  ebx, 1
    ret
MyIsValidChar ENDP

; ----------------------------------------------------------------------------
; PROC: ValidateExpression
; Full single-pass validation of infix_buffer. Runs 6 checks.
; IN:  ESI = address of infix_buffer, ECX = infix_length
; OUT: CF=0 passed (validation_passed=1),  CF=1 failed
; ----------------------------------------------------------------------------
ValidateExpression PROC
    PUSHAD

    ; --- Check 1: non-empty ---
    inc  validation_checks
    cmp  ecx, 0
    jne  VE_check2
    mov  edx, OFFSET err_empty_input
    call WriteString
    jmp  VE_fail

VE_check2:
    ; --- Check 2: legal characters ---
    inc  validation_checks
    push esi
    push ecx
VE_char_loop:
    cmp  ecx, 0
    je   VE_char_ok
    mov  al, [esi]
    call MyIsValidChar
    cmp  ebx, 0
    je   VE_char_bad
    inc  esi
    dec  ecx
    jmp  VE_char_loop
VE_char_bad:
    pop  ecx
    pop  esi
    mov  edx, OFFSET err_invalid_char
    call WriteString
    jmp  VE_fail
VE_char_ok:
    pop  ecx
    pop  esi

    ; --- Check 3: balanced parentheses ---
    inc  validation_checks
    mov  paren_balance, 0
    push esi
    push ecx
VE_paren_loop:
    cmp  ecx, 0
    je   VE_paren_done
    mov  al, [esi]
    cmp  al, '('
    jne  VE_paren_check_lbracket
    inc  paren_balance
    jmp  VE_paren_next
VE_paren_check_lbracket:
    cmp  al, '['
    jne  VE_paren_check_lbrace
    inc  paren_balance
    jmp  VE_paren_next
VE_paren_check_lbrace:
    cmp  al, '{'
    jne  VE_paren_check_close
    inc  paren_balance
    jmp  VE_paren_next
VE_paren_check_close:
    cmp  al, ')'
    jne  VE_paren_check_rbracket
    dec  paren_balance
    cmp  paren_balance, 0
    jl   VE_paren_bad
    jmp  VE_paren_next
VE_paren_check_rbracket:
    cmp  al, ']'
    jne  VE_paren_check_rbrace
    dec  paren_balance
    cmp  paren_balance, 0
    jl   VE_paren_bad
    jmp  VE_paren_next
VE_paren_check_rbrace:
    cmp  al, '}'
    jne  VE_paren_next
    dec  paren_balance
    cmp  paren_balance, 0
    jl   VE_paren_bad
VE_paren_next:
    inc  esi
    dec  ecx
    jmp  VE_paren_loop
VE_paren_done:
    cmp  paren_balance, 0
    jne  VE_paren_bad
    pop  ecx
    pop  esi
    jmp  VE_check4
VE_paren_bad:
    pop  ecx
    pop  esi
    mov  edx, OFFSET err_unbalanced_paren
    call WriteString
    jmp  VE_fail

VE_check4:
    ; --- Check 4: leading operator check ---
    inc  validation_checks
    push esi
    push ecx
VE_skip_ws_lead:
    cmp  ecx, 0
    je   VE_lead_done
    mov  al, [esi]
    cmp  al, ' '
    jne  VE_check_lead_char
    inc  esi
    dec  ecx
    jmp  VE_skip_ws_lead
VE_check_lead_char:
    call MyIsOperator
    jz   VE_lead_bad
VE_lead_done:
    pop  ecx
    pop  esi
    jmp  VE_check5
VE_lead_bad:
    pop  ecx
    pop  esi
    mov  edx, OFFSET err_leading_op
    call WriteString
    jmp  VE_fail

VE_check5:
    ; --- Check 5: trailing operator check ---
    inc  validation_checks
    mov  eax, infix_length
    cmp  eax, 0
    je   VE_check6
    dec  eax
    push esi
    add  esi, eax
VE_trail_skip:
    mov  al, [esi]
    cmp  al, ' '
    jne  VE_check_trail
    dec  esi
    jmp  VE_trail_skip
VE_check_trail:
    call MyIsOperator
    jz   VE_trail_bad
    pop  esi
    jmp  VE_check6
VE_trail_bad:
    pop  esi
    mov  edx, OFFSET err_trailing_op
    call WriteString
    jmp  VE_fail

VE_check6:
    ; --- Check 6: consecutive operators & empty parens ---
    inc  validation_checks
    push esi
    push ecx
    xor  bl, bl
    mov  bh, 0

VE_consec_loop:
    cmp  ecx, 0
    je   VE_consec_ok

    mov  al, [esi]
    cmp  al, ' '
    je   VE_consec_next

    cmp  bh, '('
    jne  VE_empty_check_lbracket
    cmp  al, ')'
    je   VE_empty_paren_bad
    jmp  VE_skip_empty_check
VE_empty_check_lbracket:
    cmp  bh, '['
    jne  VE_empty_check_lbrace
    cmp  al, ']'
    je   VE_empty_paren_bad
    jmp  VE_skip_empty_check
VE_empty_check_lbrace:
    cmp  bh, '{'
    jne  VE_skip_empty_check
    cmp  al, '}'
    je   VE_empty_paren_bad
VE_skip_empty_check:

    call MyIsOperator
    jnz  VE_not_op_curr
    cmp  bl, 1
    je   VE_consec_bad
    mov  bl, 1
    jmp  VE_save_prev
VE_not_op_curr:
    mov  bl, 0

VE_save_prev:
    mov  bh, al
VE_consec_next:
    inc  esi
    dec  ecx
    jmp  VE_consec_loop

VE_consec_ok:
    pop  ecx
    pop  esi
    jmp  VE_pass

VE_consec_bad:
    pop  ecx
    pop  esi
    mov  edx, OFFSET err_consec_op
    call WriteString
    jmp  VE_fail

VE_empty_paren_bad:
    pop  ecx
    pop  esi
    mov  edx, OFFSET err_empty_parens
    call WriteString
    jmp  VE_fail

VE_pass:
    mov  validation_passed, 1
    POPAD
    clc
    ret

VE_fail:
    mov  validation_passed, 0
    POPAD
    stc
    ret
ValidateExpression ENDP

; ----------------------------------------------------------------------------
; PROC: TokenizeExpression
; Walks infix_buffer, builds token_types[] and token_values[].
; IN:  ESI = address of infix_buffer, ECX = infix_length
; OUT: token_count set; CF=0 success, CF=1 overflow
; ----------------------------------------------------------------------------
TokenizeExpression PROC
    PUSHAD

    mov  token_count, 0
    xor  edi, edi

Tok_loop:
    cmp  ecx, 0
    je   Tok_done

    mov  al, [esi]

    cmp  al, ' '
    je   Tok_skip_ws
    cmp  al, 9
    je   Tok_skip_ws
    jmp  Tok_check_digit

Tok_skip_ws:
    inc  esi
    dec  ecx
    jmp  Tok_loop

Tok_check_digit:
    call MyIsDigit
    cmp  ebx, 1
    jne  Tok_check_op

    xor  edx, edx
Tok_digit_loop:
    cmp  ecx, 0
    je   Tok_emit_num
    mov  al, [esi]
    call MyIsDigit
    cmp  ebx, 0
    je   Tok_emit_num
    imul edx, edx, 10
    movzx eax, al
    sub  eax, '0'
    add  edx, eax
    inc  esi
    dec  ecx
    jmp  Tok_digit_loop

Tok_emit_num:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_NUM
    mov  eax, edi
    shl  eax, 2
    mov  [token_values + eax], edx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_check_op:
    call MyIsOperator
    jnz  Tok_check_paren

    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_OP
    movzx edx, al
    mov  eax, edi
    shl  eax, 2
    mov  [token_values + eax], edx
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_check_paren:
    cmp  al, '('
    je   Tok_lparen
    cmp  al, ')'
    je   Tok_rparen
    cmp  al, '['
    je   Tok_lbracket
    cmp  al, ']'
    je   Tok_rbracket
    cmp  al, '{'
    je   Tok_lbrace
    cmp  al, '}'
    je   Tok_rbrace
    inc  esi
    dec  ecx
    jmp  Tok_loop

Tok_lparen:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_LPAREN
    mov  eax, edi
    shl  eax, 2
    mov  dword ptr [token_values + eax], '('
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_rparen:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_RPAREN
    mov  eax, edi
    shl  eax, 2
    mov  dword ptr [token_values + eax], ')'
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_lbracket:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_LPAREN
    mov  eax, edi
    shl  eax, 2
    mov  dword ptr [token_values + eax], '['
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_rbracket:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_RPAREN
    mov  eax, edi
    shl  eax, 2
    mov  dword ptr [token_values + eax], ']'
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_lbrace:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_LPAREN
    mov  eax, edi
    shl  eax, 2
    mov  dword ptr [token_values + eax], '{'
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_rbrace:
    cmp  edi, TOKEN_ARRAY_SIZE
    jge  Tok_overflow
    mov  byte ptr [token_types + edi], TOKEN_TYPE_RPAREN
    mov  eax, edi
    shl  eax, 2
    mov  dword ptr [token_values + eax], '}'
    inc  esi
    dec  ecx
    inc  edi
    inc  token_count
    jmp  Tok_loop

Tok_done:
    mov  edx, OFFSET msg_tokens_label
    call WriteString
    mov  eax, token_count
    call WriteDec
    call Crlf
    POPAD
    clc
    ret

Tok_overflow:
    POPAD
    stc
    ret
TokenizeExpression ENDP

; ============================================================================
;  MODULE 2: INFIX-TO-POSTFIX CONVERSION
; ============================================================================

; ----------------------------------------------------------------------------
; PROC: OpStackPush
; IN:  AL = operator/paren char
; OUT: CF=0 success, CF=1 overflow
; ----------------------------------------------------------------------------
OpStackPush PROC
    push eax
    push ebx

    mov  ebx, op_stack_top
    cmp  ebx, OP_STACK_SIZE
    jge  OSP_overflow

    mov  byte ptr [op_stack_chars + ebx], al
    inc  op_stack_top

    mov  ebx, op_stack_top
    cmp  ebx, op_stack_peak_depth
    jle  OSP_no_peak_update
    mov  op_stack_peak_depth, ebx
OSP_no_peak_update:
    inc  op_push_count

    pop  ebx
    pop  eax
    clc
    ret

OSP_overflow:
    pop  ebx
    pop  eax
    stc
    ret
OpStackPush ENDP

; ----------------------------------------------------------------------------
; PROC: OpStackPop
; OUT: AL = popped char, CF=0 success, CF=1 underflow
; ----------------------------------------------------------------------------
OpStackPop PROC
    push ebx

    mov  ebx, op_stack_top
    cmp  ebx, 0
    je   OSPO_underflow

    dec  ebx
    mov  op_stack_top, ebx
    mov  al, byte ptr [op_stack_chars + ebx]

    inc  op_pop_count

    pop  ebx
    clc
    ret

OSPO_underflow:
    pop  ebx
    stc
    ret
OpStackPop ENDP

; ----------------------------------------------------------------------------
; PROC: OpStackPeek
; OUT: AL = top char (0 if empty), ZF=1 if empty
; ----------------------------------------------------------------------------
OpStackPeek PROC
    push ebx

    mov  ebx, op_stack_top
    cmp  ebx, 0
    je   OSPE_empty

    dec  ebx
    mov  al, byte ptr [op_stack_chars + ebx]
    cmp  ebx, 0FFFFFFFFh
    pop  ebx
    ret

OSPE_empty:
    xor  al, al
    cmp  al, 0
    pop  ebx
    ret
OpStackPeek ENDP

; ----------------------------------------------------------------------------
; PROC: GetPrecedence
; IN:  AL = operator char
; OUT: EAX = precedence level (0-3), EAX = -1 if not found
; ----------------------------------------------------------------------------
GetPrecedence PROC
    push esi
    push ebx

    mov  esi, OFFSET prec_table

GP_scan:
    mov  bl, byte ptr [esi]
    cmp  bl, 0FFh
    je   GP_not_found

    cmp  al, bl
    jne  GP_next

    movzx eax, byte ptr [esi + 1]
    pop  ebx
    pop  esi
    ret

GP_next:
    add  esi, 2
    jmp  GP_scan

GP_not_found:
    mov  eax, -1
    pop  ebx
    pop  esi
    ret
GetPrecedence ENDP

; ----------------------------------------------------------------------------
; PROC: EmitPostfixToken
; IN:  AL = token type,  EBX = token value
; OUT: CF=0 success, CF=1 overflow
; ----------------------------------------------------------------------------
EmitPostfixToken PROC
    push ecx
    push edx

    mov  ecx, postfix_count
    cmp  ecx, TOKEN_ARRAY_SIZE
    jge  EPT_overflow

    mov  byte ptr [postfix_types + ecx], al

    mov  edx, ecx
    shl  edx, 2
    mov  [postfix_values + edx], ebx

    inc  postfix_count

    pop  edx
    pop  ecx
    clc
    ret

EPT_overflow:
    pop  edx
    pop  ecx
    stc
    ret
EmitPostfixToken ENDP

; ----------------------------------------------------------------------------
; PROC: ConvertInfixToPostfix  (Shunting-Yard Algorithm)
; OUT: CF=0 success, CF=1 error
; ----------------------------------------------------------------------------
ConvertInfixToPostfix PROC
    PUSHAD

    mov  postfix_count, 0
    xor  esi, esi

CIP_loop:
    mov  eax, token_count
    cmp  esi, eax
    jge  CIP_drain

    movzx ecx, byte ptr [token_types + esi]

    mov  eax, esi
    shl  eax, 2
    mov  edx, [token_values + eax]

    cmp  cl, TOKEN_TYPE_NUM
    jne  CIP_check_op

    mov  al, TOKEN_TYPE_NUM
    mov  ebx, edx
    call EmitPostfixToken
    jc   CIP_overflow_err
    inc  esi
    jmp  CIP_loop

CIP_check_op:
    cmp  cl, TOKEN_TYPE_OP
    jne  CIP_check_lparen

    mov  bh, dl

CIP_op_loop:
    call OpStackPeek
    jz   CIP_push_op

    cmp  al, '('
    je   CIP_push_op
    cmp  al, '['
    je   CIP_push_op
    cmp  al, '{'
    je   CIP_push_op

    push eax
    mov  al, bh
    call GetPrecedence
    mov  ecx, eax

    pop  eax
    push ecx
    call GetPrecedence
    mov  edx, eax
    pop  ecx

    cmp  bh, '^'
    je   CIP_right_assoc

    cmp  edx, ecx
    jl   CIP_push_op

    jmp  CIP_pop_and_emit

CIP_right_assoc:
    cmp  edx, ecx
    jle  CIP_push_op

CIP_pop_and_emit:
    call OpStackPop
    jc   CIP_push_op
    push ebx
    movzx ebx, al
    mov  al, TOKEN_TYPE_OP
    call EmitPostfixToken
    pop  ebx
    jc   CIP_overflow_err
    jmp  CIP_op_loop

CIP_push_op:
    mov  al, bh
    call OpStackPush
    jc   CIP_stack_ovf_err
    inc  esi
    jmp  CIP_loop

CIP_check_lparen:
    cmp  cl, TOKEN_TYPE_LPAREN
    jne  CIP_check_rparen
    ; push the actual bracket character stored in token value (low byte of edx)
    mov  al, dl
    call OpStackPush
    jc   CIP_stack_ovf_err
    inc  esi
    jmp  CIP_loop

CIP_check_rparen:
    cmp  cl, TOKEN_TYPE_RPAREN
    jne  CIP_next

CIP_rparen_loop:
    call OpStackPeek
    jz   CIP_mismatch_err

    cmp  al, '('
    je   CIP_discard_lparen
    cmp  al, '['
    je   CIP_discard_lparen
    cmp  al, '{'
    je   CIP_discard_lparen

    call OpStackPop
    jc   CIP_mismatch_err
    push ebx
    movzx ebx, al
    mov  al, TOKEN_TYPE_OP
    call EmitPostfixToken
    pop  ebx
    jc   CIP_overflow_err
    jmp  CIP_rparen_loop

CIP_discard_lparen:
    call OpStackPop
    inc  esi
    jmp  CIP_loop

CIP_next:
    inc  esi
    jmp  CIP_loop

CIP_drain:
    call OpStackPeek
    jz   CIP_done

    cmp  al, '('
    je   CIP_mismatch_err
    cmp  al, '['
    je   CIP_mismatch_err
    cmp  al, '{'
    je   CIP_mismatch_err

    call OpStackPop
    jc   CIP_done
    push ebx
    movzx ebx, al
    mov  al, TOKEN_TYPE_OP
    call EmitPostfixToken
    pop  ebx
    jc   CIP_overflow_err
    jmp  CIP_drain

CIP_done:
    POPAD
    clc
    ret

CIP_stack_ovf_err:
    mov  edx, OFFSET err_op_stack_ovf
    call WriteString
    POPAD
    stc
    ret

CIP_mismatch_err:
    mov  edx, OFFSET err_mismatch_paren
    call WriteString
    POPAD
    stc
    ret

CIP_overflow_err:
    POPAD
    stc
    ret
ConvertInfixToPostfix ENDP

; ----------------------------------------------------------------------------
; PROC: PrintPostfixArray
; ----------------------------------------------------------------------------
PrintPostfixArray PROC
    PUSHAD

    mov  edx, OFFSET msg_postfix_label
    call WriteString

    xor  esi, esi

PPF_loop:
    mov  eax, postfix_count
    cmp  esi, eax
    jge  PPF_done

    movzx ecx, byte ptr [postfix_types + esi]
    mov  eax, esi
    shl  eax, 2
    mov  edx, [postfix_values + eax]

    cmp  cl, TOKEN_TYPE_NUM
    jne  PPF_print_op

    mov  eax, edx
    call WriteDec
    jmp  PPF_space

PPF_print_op:
    mov  al, dl
    call WriteChar

PPF_space:
    mov  edx, OFFSET msg_space
    call WriteString

    inc  esi
    jmp  PPF_loop

PPF_done:
    call Crlf
    POPAD
    ret
PrintPostfixArray ENDP

; ============================================================================
;  MODULE 3: POSTFIX EVALUATOR
; ============================================================================

; ----------------------------------------------------------------------------
; PROC: EvalStackPush
; IN:  EAX = signed 32-bit value
; OUT: CF=0 success, CF=1 overflow
; ----------------------------------------------------------------------------
EvalStackPush PROC
    push ebx
    push eax

    mov  ebx, eval_stack_top
    cmp  ebx, EVAL_STACK_SIZE
    jge  ESP_overflow

    mov  eax, ebx
    shl  eax, 2
    pop  ebx
    push ebx
    mov  [eval_stack + eax], ebx

    mov  eax, eval_stack_top
    inc  eax
    mov  eval_stack_top, eax

    cmp  eax, eval_stack_peak_depth
    jle  ESP_no_peak
    mov  eval_stack_peak_depth, eax
ESP_no_peak:
    inc  eval_push_count

    pop  ebx
    pop  ebx
    clc
    ret

ESP_overflow:
    pop  eax
    pop  ebx
    stc
    ret
EvalStackPush ENDP

; ----------------------------------------------------------------------------
; PROC: EvalStackPop
; OUT: EAX = popped signed value, CF=0 success, CF=1 underflow
; ----------------------------------------------------------------------------
EvalStackPop PROC
    push ebx

    mov  ebx, eval_stack_top
    cmp  ebx, 0
    je   ESPO_underflow

    dec  ebx
    mov  eval_stack_top, ebx

    mov  eax, ebx
    shl  eax, 2
    mov  eax, [eval_stack + eax]

    inc  eval_pop_count

    pop  ebx
    clc
    ret

ESPO_underflow:
    pop  ebx
    stc
    ret
EvalStackPop ENDP

; ----------------------------------------------------------------------------
; PROC: SafeDivide
; IN:  EBX = dividend,  ECX = divisor
; OUT: EAX = quotient,  CF=0 ok,  CF=1 div-by-zero
; ----------------------------------------------------------------------------
SafeDivide PROC
    push ecx

    cmp  ecx, 0
    je   SD_div_zero

    mov  eax, ebx
    cdq
    idiv ecx

    inc  arithmetic_ops_done

    pop  ecx
    clc
    ret

SD_div_zero:
    mov  edx, OFFSET err_div_zero
    call WriteString
    pop  ecx
    stc
    ret
SafeDivide ENDP

; ----------------------------------------------------------------------------
; PROC: PerformArithmetic
; IN:  AL = operator char,  EBX = left operand,  ECX = right operand
; OUT: EAX = result,  CF=0 success,  CF=1 error
; ----------------------------------------------------------------------------
PerformArithmetic PROC
    push edx

    cmp  al, '+'
    jne  PA_sub
    mov  eax, ebx
    add  eax, ecx
    inc  arithmetic_ops_done
    pop  edx
    clc
    ret

PA_sub:
    cmp  al, '-'
    jne  PA_mul
    mov  eax, ebx
    sub  eax, ecx
    inc  arithmetic_ops_done
    pop  edx
    clc
    ret

PA_mul:
    cmp  al, '*'
    jne  PA_div
    mov  eax, ebx
    imul eax, ecx
    inc  arithmetic_ops_done
    pop  edx
    clc
    ret

PA_div:
    cmp  al, '/'
    jne  PA_pow
    call SafeDivide
    jc   PA_error
    pop  edx
    clc
    ret

PA_pow:
    cmp  al, '^'
    jne  PA_unknown
    cmp  ecx, 0
    jl   PA_unknown
    je   PA_pow_zero_exp

    mov  eax, ebx
    push ecx
    dec  ecx
PA_pow_loop:
    cmp  ecx, 0
    je   PA_pow_done
    imul eax, ebx
    dec  ecx
    jmp  PA_pow_loop
PA_pow_done:
    inc  arithmetic_ops_done
    pop  ecx
    pop  edx
    clc
    ret

PA_pow_zero_exp:
    mov  eax, 1
    inc  arithmetic_ops_done
    pop  edx
    clc
    ret

PA_unknown:
    pop  edx
    stc
    ret

PA_error:
    pop  edx
    stc
    ret
PerformArithmetic ENDP

; ----------------------------------------------------------------------------
; PROC: PrintSignedResult
; IN:  EAX = signed 32-bit integer to display
; ----------------------------------------------------------------------------
PrintSignedResult PROC
    PUSHAD

    cmp  eax, 0
    jge  PSR_positive
    push eax
    mov  edx, OFFSET msg_negative_sign
    call WriteString
    pop  eax
    neg  eax

PSR_positive:
    mov  ecx, 0
    lea  edi, result_str_buffer
    add  edi, 14
    mov  byte ptr [edi], 0
    dec  edi

    cmp  eax, 0
    jne  PSR_digit_loop
    mov  byte ptr [edi], '0'
    dec  edi
    inc  ecx
    jmp  PSR_print

PSR_digit_loop:
    cmp  eax, 0
    je   PSR_print
    xor  edx, edx
    mov  ebx, 10
    div  ebx
    add  dl, '0'
    mov  byte ptr [edi], dl
    dec  edi
    inc  ecx
    jmp  PSR_digit_loop

PSR_print:
    inc  edi
    mov  edx, edi
    call WriteString

    POPAD
    ret
PrintSignedResult ENDP

; ----------------------------------------------------------------------------
; PROC: EvaluatePostfix
; OUT: eval_result = final answer, CF=0 success, CF=1 error
; ----------------------------------------------------------------------------
EvaluatePostfix PROC
    PUSHAD

    mov  eval_result_valid, 0
    xor  esi, esi

EP_loop:
    mov  eax, postfix_count
    cmp  esi, eax
    jge  EP_final_check

    movzx ecx, byte ptr [postfix_types + esi]
    mov  eax, esi
    shl  eax, 2
    mov  edx, [postfix_values + eax]

    inc  token_proc_count

    cmp  cl, TOKEN_TYPE_NUM
    jne  EP_handle_op

    mov  eax, edx
    call EvalStackPush
    jc   EP_overflow_err
    inc  esi
    jmp  EP_loop

EP_handle_op:
    call EvalStackPop
    jc   EP_underflow_err
    mov  ecx, eax

    call EvalStackPop
    jc   EP_underflow_err
    mov  ebx, eax

    mov  al, dl
    call PerformArithmetic
    jc   EP_arith_err

    call EvalStackPush
    jc   EP_overflow_err
    inc  esi
    jmp  EP_loop

EP_final_check:
    cmp  eval_stack_top, 1
    jne  EP_leftover_err

    call EvalStackPop
    jc   EP_underflow_err

    mov  eval_result, eax
    mov  eval_result_valid, 1

    mov  edx, OFFSET msg_result_label
    call WriteString
    mov  eax, eval_result
    call PrintSignedResult
    call Crlf

    POPAD
    clc
    ret

EP_underflow_err:
    mov  edx, OFFSET err_eval_underflow
    call WriteString
    POPAD
    stc
    ret

EP_overflow_err:
    mov  edx, OFFSET err_eval_overflow
    call WriteString
    POPAD
    stc
    ret

EP_arith_err:
    POPAD
    stc
    ret

EP_leftover_err:
    mov  edx, OFFSET err_leftover_ops
    call WriteString
    POPAD
    stc
    ret
EvaluatePostfix ENDP

; ============================================================================
;  MODULE 4: PERFORMANCE ANALYTICS
; ============================================================================

StartTimer PROC
    PUSHAD
    call GetMseconds
    mov  time_start_ms, eax
    POPAD
    ret
StartTimer ENDP

StopTimer PROC
    PUSHAD
    call GetMseconds
    mov  time_end_ms, eax
    sub  eax, time_start_ms
    mov  time_elapsed_ms, eax
    POPAD
    ret
StopTimer ENDP

ComputeTotalStackOps PROC
    mov  eax, op_push_count
    add  eax, op_pop_count
    add  eax, eval_push_count
    add  eax, eval_pop_count
    mov  total_stack_ops, eax
    ret
ComputeTotalStackOps ENDP

ComputeMemoryEstimate PROC
    PUSHAD

    mov  eax, infix_length
    mov  mem_input_used, eax

    mov  eax, token_count
    mov  ebx, 5
    mul  ebx
    mov  mem_token_used, eax

    mov  eax, postfix_count
    mul  ebx
    mov  mem_postfix_used, eax

    mov  eax, op_stack_peak_depth
    mov  mem_op_stack_peak, eax

    mov  eax, eval_stack_peak_depth
    shl  eax, 2
    mov  mem_eval_stack_peak, eax

    mov  eax, mem_input_used
    add  eax, mem_token_used
    add  eax, mem_postfix_used
    add  eax, mem_op_stack_peak
    add  eax, mem_eval_stack_peak
    mov  mem_total_estimate, eax

    POPAD
    ret
ComputeMemoryEstimate ENDP

DisplayAnalyticsReport PROC
    PUSHAD

    call StopTimer
    call ComputeMemoryEstimate
    call ComputeTotalStackOps

    mov  edx, OFFSET msg_analytics_hdr
    call WriteString

    mov  edx, OFFSET msg_time_ms
    call WriteString
    mov  eax, time_elapsed_ms
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_op_pushes
    call WriteString
    mov  eax, op_push_count
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_op_pops
    call WriteString
    mov  eax, op_pop_count
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_eval_pushes
    call WriteString
    mov  eax, eval_push_count
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_eval_pops
    call WriteString
    mov  eax, eval_pop_count
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_total_s_ops
    call WriteString
    mov  eax, total_stack_ops
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_tok_proc
    call WriteString
    mov  eax, token_proc_count
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_arith_done
    call WriteString
    mov  eax, arithmetic_ops_done
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_mem_est
    call WriteString
    mov  eax, mem_total_estimate
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_op_peak
    call WriteString
    mov  eax, op_stack_peak_depth
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_eval_peak
    call WriteString
    mov  eax, eval_stack_peak_depth
    call WriteDec
    call Crlf

    mov  edx, OFFSET msg_analytics_ftr
    call WriteString

    POPAD
    ret
DisplayAnalyticsReport ENDP

; ----------------------------------------------------------------------------
; PROC: ResetAllMetrics
; ----------------------------------------------------------------------------
ResetAllMetrics PROC
    PUSHAD

    mov  op_stack_top,          0
    mov  eval_stack_top,        0
    mov  token_count,           0
    mov  postfix_count,         0

    mov  op_push_count,         0
    mov  op_pop_count,          0
    mov  eval_push_count,       0
    mov  eval_pop_count,        0
    mov  total_stack_ops,       0
    mov  token_proc_count,      0
    mov  validation_checks,     0
    mov  arithmetic_ops_done,   0

    mov  op_stack_peak_depth,   0
    mov  eval_stack_peak_depth, 0

    mov  mem_input_used,        0
    mov  mem_token_used,        0
    mov  mem_postfix_used,      0
    mov  mem_op_stack_peak,     0
    mov  mem_eval_stack_peak,   0
    mov  mem_total_estimate,    0

    mov  infix_length,          0
    mov  paren_balance,         0
    mov  validation_passed,     0
    mov  empty_input_flag,      0
    mov  eval_result_valid,     0
    mov  eval_result,           0
    mov  time_elapsed_ms,       0

    mov  ecx, INPUT_BUFFER_SIZE
    mov  edi, OFFSET infix_buffer
    xor  eax, eax
    rep  stosb

    mov  ecx, TOKEN_ARRAY_SIZE
    mov  edi, OFFSET token_types
    rep  stosb

    mov  ecx, TOKEN_ARRAY_SIZE
    mov  edi, OFFSET postfix_types
    rep  stosb

    mov  ecx, TOKEN_ARRAY_SIZE
    mov  edi, OFFSET token_values
    rep  stosd

    mov  ecx, TOKEN_ARRAY_SIZE
    mov  edi, OFFSET postfix_values
    rep  stosd

    mov  ecx, EVAL_STACK_SIZE
    mov  edi, OFFSET eval_stack
    rep  stosd

    POPAD
    ret
ResetAllMetrics ENDP

; ============================================================================
;  MAIN PROCEDURE
; ============================================================================
main PROC
    mov  edx, OFFSET prompt_welcome
    call WriteString

main_loop:
    call ResetAllMetrics
    call StartTimer

    call ReadInfixInput
    jz   main_empty_input

    mov  esi, OFFSET infix_buffer
    mov  ecx, infix_length
    call ValidateExpression
    jc   main_show_separator

    mov  esi, OFFSET infix_buffer
    mov  ecx, infix_length
    call TokenizeExpression
    jc   main_show_separator

    call ConvertInfixToPostfix
    jc   main_show_separator

    call PrintPostfixArray

    call EvaluatePostfix
    jc   main_show_separator

    call DisplayAnalyticsReport
    jmp  main_ask_again

main_empty_input:
    mov  edx, OFFSET err_empty_input
    call WriteString

main_show_separator:
    mov  edx, OFFSET prompt_separator
    call WriteString

main_ask_again:
    mov  edx, OFFSET prompt_again
    call WriteString

    call ReadChar
    call Crlf
    call Crlf

    cmp  al, 'Y'
    je   main_loop
    cmp  al, 'y'
    je   main_loop

    mov  edx, OFFSET msg_goodbye
    call WriteString

    INVOKE ExitProcess, 0
main ENDP

END main
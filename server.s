.intel_syntax noprefix
.globl _start

.section .text

# syscall args in order: rdi, rsi, rdx, r10, r8, r9
_start:
    mov rdi, 0

    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    mov rdx, IPPROTO_IP
    mov rax, 41     # sys_socket
    syscall
    
    push struct_addr #push struct_addr on stack

    mov rdi, 3      # bind(0)
    mov rsi, rsp    # point second argument to stack
    mov rdx, 16
    mov rax, 49     # sys_bind
    syscall
    
    mov rdi, 3
    mov rsi, 0
    mov rax, 0x32   # listen
    syscall

    mov rdi, 3
    mov rsi, 0
    mov rdx, 0
    mov rax, 0x2b   # accept
    syscall

    mov rax, 0x27   # getpid
    syscall
    mov rbx, rax

    mov rax, 0x39   # fork
    syscall

    mov rax, 0x27   # getpid
    syscall

    cmp rax, rbx
    jne child

    mov rdi, 4
    mov rax, 0x03   # close4
    syscall

    mov rdi, 3
    mov rsi, 0
    mov rdx, 0
    mov rax, 0x2b   # accept
    syscall

    mov rdi, 0      # exit(0)
    mov rax, 60     # sys_bind
    syscall
    
    jmp done

    child:

        mov rdi, 3
        mov rax, 0x03   # close 4
        syscall

        mov rdi, 4
        mov rsi, rsp
        mov rdx, 512
        mov rax, 0x00   # read 4
        syscall

        mov r10, rax    # read length
        
        mov rbp, rsp
        add rbp, 5  # remove POST thing

        # loops check for space in POST requests, stops when it finds it (ascii for space is 0x20)
        mov rbx, 0
        mov rcx, 0
        spaceloop:
            mov cl, byte ptr [rbp+rbx]
            cmp cl, 0x20
            je spaceloopdone
            inc rbx
            jmp spaceloop
        spaceloopdone:
        mov byte ptr [rbp+rbx], 0

        mov rdi, rbp
        mov rsi, 0x41 # O_WRONLY (1) + O_CREAT (100)
        mov rdx, 0777
        mov rax, 0x2   # open fd 3
        syscall

        mov rbp, rsp

        # loops check for \r\n\r\n in POST requests, stops when it finds it
        mov rbx, 0
        mov rcx, 0
        filecontentloop:
            mov cx, word ptr [rbp+rbx]
            cmp cx, 0x0d0a0d0a
            je filecontentloopdone
            inc rbx
            jmp filecontentloop
        filecontentloopdone:
        dec rbx
        add rbx, 4 # get rid of the \r\n\r\n by shifting 4 bytes
        add rbp, rbx



        # read length = length of string (r10) - rbx
        sub r10, rbx

        mov rdi, 3
        mov rsi, rbp
        mov rdx, r10
        mov rax, 0x01   # write fd 3
        syscall

        mov rdi, 3
        mov rax, 0x03   # close fd 3
        syscall

        # write 200 ok response
        push HTTP_RESP_ASCII+16
        push HTTP_RESP_ASCII+8
        push HTTP_RESP_ASCII

        mov rdi, 4
        mov rbp, rsp
        mov rsi, rbp
        mov rdx, 19
        mov rax, 0x01   # write 4
        syscall

        mov rdi, 0      # exit(0)
        mov rax, 60     # sys_bind
        syscall
    done:
        nop

.section .data
AF_INET: .quad 2
SOCK_STREAM: .quad 1
IPPROTO_IP: .quad 0
HTTP_RESP_ASCII: .string "HTTP/1.0 200 OK\r\n\r\n"
struct_addr:
.word 0x0002
.word 0x5000
.byte 0,0,0,0

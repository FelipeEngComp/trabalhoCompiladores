ID[a-zA-Z][a-zA-Z0-9]*
DIGITOS[0-9]
ESPACOBRANCO[ ]
LETRA[a-zA-Z]
QUEBRADELINHA[\n]
TAB[\t ]

%{
    #include<iostream>
    #include<stdio.h>
    #include<stdlib.h>
    #define YY_DECL extern "C" int yylex()
    #include<strings.h>
   // #include"ast.h"
    extern TABELADESIMBOLOS symTab[TAMANHOTABELA];
    extern int tabelaDeSymSize;
    //using namespace std;
   	//forma de enviar os tokens a serem analizados pelo parser
    int salvaLinha;	
    
    static TABELADESIMBOLOS novoNo();
    static int installId(char *id);
    static int procura(char *s);
%}
%option yylineno
%x COMENTARIO

%%

{QUEBRADELINHA}

\/\* { BEGIN(COMENTARIO);salvaLinha = yylineno;}
<COMENTARIO>\*\/    {   // end of a comment: go back to normal parsing.
	BEGIN(INITIAL);
	}
<COMENTARIO>(.|\n) ;
<COMENTARIO><<EOF>> {printf("(%d,ERROR,\"/*\")\n",yylineno); return 0;}

"else"                  {return ELSE;}
"if"                    {return IF;}
"int"                   {yylval.ival = installId(yytext); return INT;}
"return"                {yylval.ival = installId(yytext); return RETURN;}
"void"                  {yylval.ival = installId(yytext); return VOID;}
"while"                 {return WHILE;}
"+"                     {return PLUS;}
"-"                     {return MINUS;}
"*"                     {return TIMES;}
"/"                     {return DIVIDE;}
"<"					    { return '<'; }
">"					    { return '>'; }
"="                     {return EQUALS;}
";"                     {return ';';}
","                     {return ',';}
"("                     {return LPAREN;}
")"                     {return RPAREN;}
("["|"<:")				{ return '[';}
("]"|":>")				{ return ']';}
("{"|"<%")				{ return '{';}
("}"|"%>")				{ return '}';}
"<="					{ return LE_OP; }
">="					{ return GE_OP; }
"=="					{ return EQ_OP; }
"!="					{ return NE_OP; }

{ESPACOBRANCO}+|{TAB}+|{QUEBRADELINHA} /*ignora espaco em branco*/
 
{DIGITOS}+ {yylval.ival = atoi(yytext); return NUM;}

{ID}+ {yylval.ival = installId(yytext); return ID;}

{DIGITOS}+{ID} {printf("(%d,ERROR,\"%s\")\n",yylineno,yytext); return 0;}

. {printf("(%d,ERROR,\"%s\")\n",yylineno,yytext); return 0;}
%%

TABELADESIMBOLOS novoNo(){
    return ((TABELADESIMBOLOS)malloc(sizeof(SYMTABNODE)));
}

int installId(char *id){

    extern TABELADESIMBOLOS symTab[TAMANHOTABELA];
    extern int tabelaDeSymSize;
    int index;

    index = procura(id);

    if (index >= 0){
        return (index);
    }else if(tabelaDeSymSize >= TAMANHOTABELA){
         return (NOTHING);   
    }else{
        symTab[tabelaDeSymSize] = novoNo();
        strncpy(symTab[tabelaDeSymSize]->identifier,id,IDLENGTH);
        symTab[tabelaDeSymSize]->identifier[IDLENGTH-1] = '\0';
        return(tabelaDeSymSize++);
    }
}    

int procura(char *s){
    extern TABELADESIMBOLOS symtab[TAMANHOTABELA];
    extern int tabelaDeSymSize;
    int i;

    for(i = 0; i<tabelaDeSymSize;i++){
        if(strncmp(s,symTab[i]->identifier,IDLENGTH)==0){
            return (i);            
        }
    }
    return (-1);    
}

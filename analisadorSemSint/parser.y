%{ 
    #include<stdio.h>
    #include<iostream>
    #include <sstream>
    #include<stdlib.h>
    #include<strings.h>
    #include <string>
    #include <fstream>
    #include<map>
    #include<list>
    using namespace std;

    #define TAMANHOTABELA   50
    #define IDLENGTH     15
    #define NOTHING      -1
    #define INDENTOFFSET  2

    extern "C" int yylex();
    extern "C" int yyparse();
    extern "C" FILE *yyin;
    
    void yyerror(const char *s);

    enum ParseTreeNodeType{PROGRAM, DECLARATIONLIST, DECLARATION,
    VARDECLARATION, IDVARDECLARATION, VETORVARDECLARATION, TYPESPECIFIER, FUNDECLARATION, PARAMS, PARAMSVOID,PARAMSLIST,
    PARAMLIST, PARAM, IDPARAM, VETORPARAM, COMPOUNDSTMT, LOCALDECLARATIONS, STATEMENTLIST, STATEMENT, 
    EXPRESSIONSTMT, EMPEXSTMT, SELECTIONSTMT, IFSELECTIONSTMT, ELSESELECTIONSTMT, ITERATIONSTMT, RETURNSTMT, RETURNSTMTEMP,
    RETURNSTMTEXP, EXPRESSION, EQUALSEXPRESSION, OTHEREXPRESSION, VAR, IDVAR, VETORVAR, SIMPLEEXPRESSION,
    ONESIMPLEEXPRESSION, TWOSIMPLEEXPRESSION,
    RELOP, ADDITIVEEXPRESSION, ONEADDITIVEEXPRESSION, TWOADDITIVEEXPRESSION, ADDOP, TERM, ONETERM, TWOTERM, MULOP, FACTOR,
    VARFACTOR, CALLFACTOR, NUMFACTOR, CALL, ARGS, ARGLIST};

    const char *NodeName[] = {"PROGRAM", "DECLARATIONLIST", "DECLARATION",
    "VARDECLARATION","IDVARDECLARATION", "VETORVARDECLARATION", "TYPESPECIFIER", "FUNDECLARATION", "PARAMS", "PARAMSVOID","PARAMSLIST", "PARAMLIST", 
    "PARAM", "IDPARAM", "VETORPARAM" ,"COMPOUNDSTMT", "LOCALDECLARATIONS", "STATEMENTLIST", "STATEMENT", 
    "EXPRESSIONSTMT", "EMPEXSTMT", "SELECTIONSTMT", "IFSELECTIONSTMT", "ELSESELECTIONSTMT", "ITERATIONSTMT", "RETURNSTMT", "RETURNSTMTEMP",
    "RETURNSTMTEXP", "EXPRESSION","EQUALSEXPRESSION", "OTHEREXPRESSION", "VAR","IDVAR", "VETORVAR" , "SIMPLEEXPRESSION","ONESIMPLEEXPRESSION", "TWOSIMPLEEXPRESSION", "RELOP", "ADDITIVEEXPRESSION",
    "ONEADDITIVEEXPRESSION", "TWOADDITIVEEXPRESSION","ADDOP", "TERM","ONETERM", "TWOTERM", "MULOP", "FACTOR","VARFACTOR", "CALLFACTOR", "NUMFACTOR", "CALL", "ARGS", "ARGLIST"};

    #ifndef TRUE
    #define TRUE 1
    #endif

    #ifndef FALSE
    #define FALSE 0
    #endif

    #ifndef NULL
    #define NULL 0
    #endif

    struct treeNode{
        int item1;
        int item2;
        int nodeId;
        struct treeNode *first;
        struct treeNode *second;
        struct treeNode *third;
    };

    typedef struct treeNode TREE_NODE;
    typedef TREE_NODE *TERNARY_TREE;

    struct paramTypes{
        string type;
        string funcaoNome;
        string nome[10000];
        string tipo[10000];
        int size;
    };
    typedef struct paramTypes PARAM_TYPES;
    PARAM_TYPES p_types,p_funcoes;
    int cArgs = 0,compArgs = 0;//conta argumentos/parametros

    struct declaredArgs{
        string nome;
        string tipo;
        bool podeOberacao;
    };
    typedef struct declaredArgs DECLARED_ARGS;
    DECLARED_ARGS d_args;

    typedef map<string,string> DECLARE;

    typedef list<DECLARE>ESCOPO;
   

    /*---------------declaracoes-----------*/
    TERNARY_TREE create_node(int,int,int,TERNARY_TREE,TERNARY_TREE,TERNARY_TREE);
    void PrintTree(TERNARY_TREE);
    
    void semanticVerify(list<string>,list<string>,int,list<string>,list<string>);
    
    void verifyFuncao(list<list<string> >,list<string>,list<string>,list<string>,list<string>,list<string>,list<string>);

    void verifyEscopo(ESCOPO,list<string>,list<string>,
    list<string>,list<string>,list<string>,list<string>,list<string>,map<string,string>,map<string,string>);

    void verifyArgsFunc(ESCOPO,list<bool>,list<DECLARED_ARGS>,list<PARAM_TYPES>,list<list<PARAM_TYPES> >,list<string>,int);

    /*DEFINICAO DA TABELA DE SIMBOLOS*/
    struct symTabNode{
        char identifier[IDLENGTH];
    };

    typedef struct symTabNode SYMTABNODE;
    typedef SYMTABNODE *TABELADESIMBOLOS;

    TABELADESIMBOLOS symTab[TAMANHOTABELA];

    int tabelaDeSymSize = 0;
    int verificaMain = 0,deepFun = 0;
    ofstream saida ;
    stringstream convert;
    bool verificaVoid = true,verificaGlobal = true,
    verificaUltimaFuncao = false, funcaoInt = false, operacao = false,
    returnExp = false, returnEmp = false, expCall = false,estouEmArgs = false,verify = false;
    string cmp;
    //DECLARACAO DAS LISTAS PARA ANALISE SEMANTICA E SAIDA DA AST
    list<string>listProgram,listFuncName,listDecVar,listNomesVariaveis,listCall,listFuncInt;
    list<string>declareGlobais,declareArrayGlobais,declareArrayLocais,declareLocais,
    idVars,vetVars,argVars,callOperation,funcReturn,funcRemp,callReturn,salvaParamFuncao;

    list<bool>verificaArgs;

    list<list<string> >verArgumentos;
    list<string> comparaArgs;
    ESCOPO escopo;
    map<string,string>declaracoes,variaveis,globais;
   
    list<PARAM_TYPES> args,funcoes_param;
    list<DECLARED_ARGS>dclArgs;
    list<list<PARAM_TYPES> > funcoes,argumentos;

    char * nomeDoArquivo;
%}

%start program

%union{
    int ival;
    char *sval;
    TERNARY_TREE tVal;
}

%error-verbose

%token <ival> NUM
%token <ival> INT
%token <ival> VOID
%token <ival> ID 
%token IF ELSE WHILE RETURN 
%token PLUS MINUS TIMES DIVIDE LPAREN RPAREN EQUALS LE_OP GE_OP  EQ_OP NE_OP
%token '>' '<' ';' ',' '[' ']' '{' '}' 


%left PLUS MINUS 
%left TIMES DIVIDE
%left LPAREN RPAREN LE_OP GE_OP EQ_OP NE_OP
%left '[' ']' '{' '}' ',' '>' '<'
%right ELSE

%type <tVal> program declarationList declaration
    varDeclaration typeSpecifier funDeclaration params paramList 
    param compoundStmt localDeclarations statementList statement 
    expressionStmt selectionStmt iterationStmt returnStmt expression 
    var simpleExpression relop additiveExpression addop term mulop 
    factor call args argList

%%

program: declarationList {
                            //cout<< "Iniciando Program"<<endl;
                            TERNARY_TREE ParseTree;
                            ParseTree = create_node(NOTHING,NOTHING,PROGRAM,$1,NULL,NULL);
                            PrintTree(ParseTree);
                        }
       ;

declarationList:declarationList declaration{
                        
                        //cout<< "declarationList declaration"<<endl;
                        $$ = create_node(NOTHING,NOTHING,DECLARATIONLIST,$1,$2,NULL);
                  } 
                | declaration{
                        //cout<< "declaration"<<endl;
                        $$ = create_node(NOTHING,NOTHING,DECLARATIONLIST,$1,NULL,NULL);
                  }   
                ;

declaration:varDeclaration{
                //cout<< "varDeclaration"<<endl;
                $$ = create_node(NOTHING,NOTHING,DECLARATION,$1,NULL,NULL);
            } 
            |funDeclaration{
                //cout<< "funDeclaration"<<endl;
                $$ = create_node(NOTHING,NOTHING,DECLARATION,$1,NULL,NULL);
            } 
            ;
            
varDeclaration:typeSpecifier ID';'{
                    //cout<< "typeSpecifier ID';'"<<endl;
                    $$ = create_node($2,NOTHING,IDVARDECLARATION,$1,NULL,NULL);
               }
               | typeSpecifier ID'['NUM']'';'{
                   //cout<< "typeSpecifier ID'['NUM']'';'"<<endl;
                    $$ = create_node($2,$4,VETORVARDECLARATION,$1,NULL,NULL);
               }
               ;

typeSpecifier: INT{
                    //cout<< "INT"<<endl;
                    $$ = create_node($1,NOTHING,TYPESPECIFIER,NULL,NULL,NULL);
               }
             | VOID{
                    //cout<< "VOID"<<endl;
                    $$ = create_node($1,NOTHING,TYPESPECIFIER,NULL,NULL,NULL);
               }   
             ;


funDeclaration: typeSpecifier ID LPAREN params RPAREN compoundStmt{
                    //cout<< "typeSpecifier ID LPAREN params RPAREN compoundStmt"<<endl;
                    $$ = create_node($2,NOTHING,FUNDECLARATION,$1,$4,$6);
                } 
                ;

params: paramList{
                   // cout<< "paramList"<<endl;
                    $$ = create_node(NOTHING,NOTHING,PARAMSLIST,$1,NULL,NULL);
               } 
        | VOID{
                  //  cout<< "VOID"<<endl;
                    $$ = create_node($1,NOTHING,PARAMSVOID,NULL,NULL,NULL);
            } 
      ;

paramList: paramList ',' param{
                    //cout<< "paramList ',' param"<<endl;
                    $$ = create_node(NOTHING,NOTHING,PARAMLIST,$1,$3,NULL);
           }
          | param{
                    //cout<< "param"<<endl;
                    $$ = create_node(NOTHING,NOTHING,PARAMLIST,$1,NULL,NULL);
            } 
          ;

param: typeSpecifier ID{
                    //cout<< "typeSpecifier ID"<<endl;
                    $$ = create_node($2,NOTHING,IDPARAM,$1,NULL,NULL);
       } 
     | typeSpecifier ID'[' ']'{
                   // cout<< "typeSpecifier ID'[' ']'"<<endl;
                    $$ = create_node($2,NOTHING,VETORPARAM,$1,NULL,NULL);
        }  
     ;

compoundStmt: '{' localDeclarations statementList '}'{
                    //cout<< "localDeclarations varDeclaration"<<endl;
                    $$ = create_node(NOTHING,NOTHING,COMPOUNDSTMT,$2,$3,NULL);
               } 
            ;

localDeclarations: localDeclarations varDeclaration{
                    //cout<< "localDeclarations varDeclaration"<<endl;
                    $$ = create_node(NOTHING,NOTHING,LOCALDECLARATIONS,$1,$2,NULL);
                 } 
                 | {
                   // cout<< "Vazio"<<endl; 
                    $$ = create_node(NOTHING,NOTHING,LOCALDECLARATIONS,NULL,NULL,NULL);}
                 ;

statementList: statementList statement{
                   // cout<< "statementList statement"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENTLIST,$1,$2,NULL);
               } 
              |     {   //cout<< "Vazio"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENTLIST,NULL,NULL,NULL);}
              ;

statement: expressionStmt{
                    //cout<< "expressionStmt"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENT,$1,NULL,NULL);
           } 
         | compoundStmt{
                   // cout<< "compoundStmt"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENT,$1,NULL,NULL);
           } 
         | selectionStmt{
                    //cout<< "selectionStmt"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENT,$1,NULL,NULL);
           } 
         | iterationStmt{
                    //cout<< "iterationStmt"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENT,$1,NULL,NULL);
           } 
         | returnStmt{
                   // cout<< "returnStmt"<<endl;
                    $$ = create_node(NOTHING,NOTHING,STATEMENT,$1,NULL,NULL);
           } 
         ;

expressionStmt: expression';'{
                  //  cout<< "expression';'"<<endl;
                    $$ = create_node(NOTHING,NOTHING,EXPRESSIONSTMT,$1,NULL,NULL);
               } 
               | ';'{
                  //  cout<< ";"<<endl;
                    $$ = create_node(NOTHING,NOTHING,EMPEXSTMT,NULL,NULL,NULL);
               }
               ;

selectionStmt:  IF LPAREN expression RPAREN statement{
                    //cout<< "IF LPAREN expression RPAREN statement"<<endl;
                    $$ = create_node(NOTHING,NOTHING,IFSELECTIONSTMT,$3,$5,NULL);
               } 
              | IF LPAREN expression RPAREN statement  ELSE statement{
                   // cout<< "IF LPAREN expression RPAREN statement  ELSE statement"<<endl;
                    $$ = create_node(NOTHING,NOTHING,ELSESELECTIONSTMT,$3,$5,$7);
               } 
              ;                  

iterationStmt: WHILE LPAREN expression RPAREN statement{
                  //  cout<< "WHILE LPAREN expression RPAREN statement"<<endl;
                    $$ = create_node(NOTHING,NOTHING,ITERATIONSTMT,$3,$5,NULL);
               } 
              ;

returnStmt:  RETURN';'{
                    //cout<< "RETURN';'"<<endl;
                    $$ = create_node(RETURN,NOTHING,RETURNSTMTEMP,NULL,NULL,NULL);
               } 
           | RETURN expression';'{
                   // cout<< "RETURN expression';'"<<endl;
                    $$ = create_node(RETURN,NOTHING,RETURNSTMTEXP,$2,NULL,NULL);
               } 
           ;                

expression: var EQUALS expression{
                   // cout<< "var EQUALS expression"<<endl;
                    $$ = create_node(EQUALS,NOTHING,EQUALSEXPRESSION,$1,$3,NULL);
               }
          | simpleExpression{
                   // cout<< "simpleExpression"<<endl;
                    $$ = create_node(NOTHING,NOTHING,OTHEREXPRESSION,$1,NULL,NULL);
               } 
          ;

var: ID{
        //cout<< "ID"<<endl;
        $$ = create_node($1,NOTHING,IDVAR,NULL,NULL,NULL);
     }
   | ID'['expression']'{
        //cout<< "ID'['expression']'"<<endl;
        $$ = create_node($1,NOTHING,VETORVAR,$3,NULL,NULL);
    }
   ;   

simpleExpression: additiveExpression relop additiveExpression{
                   // cout<< "additiveExpression relop additiveExpression"<<endl;
                    $$ = create_node(NOTHING,NOTHING,TWOSIMPLEEXPRESSION,$1,$2,$3);
               } 
                | additiveExpression{
                   // cout<< "additiveExpression"<<endl;
                    $$ = create_node(NOTHING,NOTHING,ONESIMPLEEXPRESSION,$1,NULL,NULL);
               }             
                ;
relop: LE_OP{
                    $$ = create_node(LE_OP,NOTHING,RELOP,NULL,NULL,NULL);
        }
     | '<'{
                    $$ = create_node('<',NOTHING,RELOP,NULL,NULL,NULL);
        }
     | '>'{
                    $$ = create_node('>',NOTHING,RELOP,NULL,NULL,NULL);
        }
     | GE_OP{
                    $$ = create_node(GE_OP,NOTHING,RELOP,NULL,NULL,NULL);
        }
     | EQ_OP{
                    $$ = create_node(EQ_OP,NOTHING,RELOP,NULL,NULL,NULL);
            }
     | NE_OP{
                    $$ = create_node(NE_OP,NOTHING,RELOP,NULL,NULL,NULL);
            }
     ;
 

additiveExpression:  additiveExpression addop term{
                    $$ = create_node(NOTHING,NOTHING,TWOADDITIVEEXPRESSION,$1,$2,$3);
                    } 
                   | term{
                    $$ = create_node(NOTHING,NOTHING,ONEADDITIVEEXPRESSION,$1,NULL,NULL);
                    } 
                   ;
addop: PLUS{
            $$ = create_node(PLUS,NOTHING,ADDOP,NULL,NULL,NULL);
        }
     | MINUS{
            $$ = create_node(MINUS,NOTHING,ADDOP,NULL,NULL,NULL);
        }
     ;

term: term mulop factor{
                    $$ = create_node(NOTHING,NOTHING,TWOTERM,$1,$2,$3);
       } 
    | factor{
                    $$ = create_node(NOTHING,NOTHING,ONETERM,$1,NULL,NULL);
      } 
    ;
   
mulop: TIMES{
                    $$ = create_node(TIMES,NOTHING,MULOP,NULL,NULL,NULL);
    }
     |DIVIDE{
                    $$ = create_node(DIVIDE,NOTHING,MULOP,NULL,NULL,NULL);
     }
     ;

factor: LPAREN expression RPAREN{
                    $$ = create_node(NOTHING,NOTHING,FACTOR,$2,NULL,NULL);
        } 
      | var{
                    $$ = create_node(NOTHING,NOTHING,VARFACTOR,$1,NULL,NULL);
        } 
      | call{
                    $$ = create_node(NOTHING,NOTHING,CALLFACTOR,$1,NULL,NULL);
        } 
      | NUM{
                    $$ = create_node($1,NOTHING,NUMFACTOR,NULL,NULL,NULL);
        } 
      ;

call: ID LPAREN args RPAREN{
                    $$ = create_node($1,NOTHING,CALL,$3,NULL,NULL);
      }
    ;    

args: argList{
                    $$ = create_node(NOTHING,NOTHING,ARGS,$1,NULL,NULL);
      } 
    | {
                    $$ = create_node(NOTHING,NOTHING,ARGS,NULL,NULL,NULL);
    }
    ;
argList: argList ',' expression{
                    $$ = create_node(NOTHING,NOTHING,ARGLIST,$1,$3,NULL);
         } 
       | expression{
                    $$ = create_node(NOTHING,NOTHING,ARGLIST,$1,NULL,NULL);
        } 
       ;        
%%


TERNARY_TREE create_node(int ival,int ival2, int case_identifier, TERNARY_TREE
p1, TERNARY_TREE p2, TERNARY_TREE p3){

    TERNARY_TREE t;
    t = (TERNARY_TREE)malloc(sizeof(TREE_NODE));
    t->item1 = ival;
    t->item2 = ival2;
    t->nodeId = case_identifier;
    t->first = p1;
    t->second = p2;
    t->third = p3;
    return(t);
}

void PrintTree(TERNARY_TREE t){
    if (t == NULL) return;
        switch (t->nodeId){

            case PROGRAM:
                
                listProgram.push_back("[program");
                listFuncName.push_back("input");//declarados como funcoes
                listFuncInt.push_back("input");//reconhece como inteiro
                listFuncName.push_back("println");//adicionar println e input para que nao possam ser 
                PrintTree(t->first);
                listProgram.push_back("]");
                //verifica correcoes semanticas.
                
                semanticVerify(listFuncName,listDecVar,verificaMain,listNomesVariaveis,listProgram);
                for (list<string>::iterator it=listProgram.begin(); it!=listProgram.end() ; ++it){
                    saida<<*it;
                    
                }
                saida<<"\n";
                   
                return;
            break;

            case IDVARDECLARATION:
                
                    listProgram.push_back("[var-declaration");
                    listProgram.push_back("[");
                    PrintTree(t->first);
                    listProgram.push_back("]");
                    listProgram.push_back("[");
                    listProgram.push_back(symTab[t->item1]->identifier);
                    listProgram.push_back("]");
                    listProgram.push_back("]");
                
                //salva variavel global
                if (verificaGlobal){
                    if (!verificaUltimaFuncao){
                        declareGlobais.push_back(symTab[t->item1]->identifier);
                        listNomesVariaveis.push_back(symTab[t->item1]->identifier);
                        if (globais.find(symTab[t->item1]->identifier) == globais.end()){
                            globais.insert(pair<string,string>(symTab[t->item1]->identifier,"normal"));
                        }else{
                            cout<<"overload da variavel global \""<<symTab[t->item1]->identifier<<"\""<<endl;
                            exit(0);
                        }
                    }else{
                        cout<<"Variavel declarada depois do \"void main(void)\" "<<endl;
                    }                        
                        
                }else{
                    declareLocais.push_back(symTab[t->item1]->identifier);
                    if (declaracoes.find(symTab[t->item1]->identifier) == declaracoes.end()){
                        declaracoes.insert(pair<string,string>(symTab[t->item1]->identifier,"normal"));
                    }else{
                        cout<<"overload da variavel \""<<symTab[t->item1]->identifier<<"\""<<endl;
                        exit(0);
                    }
                }
                //salva o nome das variaveis globais em uma lista geral para verificar com o nome das funcoes
                
                
                return;
            break;

            case VETORVARDECLARATION:
                
                    convert << t->item2;
                    listProgram.push_back("[var-declaration ");
                    listProgram.push_back("[");
                    PrintTree(t->first);
                    listProgram.push_back("]");
                    listProgram.push_back("[");
                    listProgram.push_back(symTab[t->item1]->identifier);
                    listProgram.push_back("]");
                    listProgram.push_back("[");
                    listProgram.push_back(convert.str());
                    listProgram.push_back("]");
                    listProgram.push_back("]");
                    convert.str("");
                
                //salva variavel global
                if (verificaGlobal){
                    if (!verificaUltimaFuncao){
                        declareArrayGlobais.push_back(symTab[t->item1]->identifier);
                        listNomesVariaveis.push_back(symTab[t->item1]->identifier);
                        if (globais.find(symTab[t->item1]->identifier) == globais.end()){
                            globais.insert(pair<string,string>(symTab[t->item1]->identifier,"vetor"));
                        }else{
                            cout<<"overload da variavel global \""<<symTab[t->item1]->identifier<<"\""<<endl;
                            exit(0);
                        }
                    }else{
                        cout<<"Variavel declarada apos o \"void main(void)\" "<<endl;
                        
                    }     
                }else{
                    declareArrayLocais.push_back(symTab[t->item1]->identifier);
                    if (declaracoes.find(symTab[t->item1]->identifier) == declaracoes.end()){
                        declaracoes.insert(pair<string,string>(symTab[t->item1]->identifier,"vetor"));
                    }else{
                        cout<<"overload da variavel \""<<symTab[t->item1]->identifier<<"\""<<endl;
                        exit(0);
                    }                }    
                
                return; 
            break;
            
            case TYPESPECIFIER:
                //lista que vai verificar se alguma var foi declarada como void
                if (verificaVoid){
                    listDecVar.push_back(symTab[t->item1]->identifier);
                }//verifica se o tipo da funcao e void
                 cmp = symTab[t->item1]->identifier;
                if (cmp.compare("void")==0){
                    verificaMain ++;
                }else{
                    funcaoInt = true;
                }
                p_funcoes.type = symTab[t->item1]->identifier;    
                listProgram.push_back(symTab[t->item1]->identifier);
            break;

            case FUNDECLARATION:
                if (!verificaUltimaFuncao){
                    verificaGlobal = false;
                    verificaMain = 0;
                    verificaVoid = false;
                    funcaoInt = false;
                    returnExp = false;
                    returnEmp = false;
                    escopo.push_front(globais);
                    
                    listProgram.push_back("[fun-declaration[");
                    PrintTree(t->first);
                    if (funcaoInt){
                        listFuncInt.push_back(symTab[t->item1]->identifier);
                    }
                    bool verificaReturn = funcaoInt;
                    

                    salvaParamFuncao.push_back(symTab[t->item1]->identifier);

                    verificaVoid = true;
                    listProgram.push_back("][");

                    //verifica se o nome da funcao e main
                    cmp = symTab[t->item1]->identifier;
                    if ( verificaMain == 1 && cmp.compare("main")==0){
                        verificaMain++;
                    }

                    p_funcoes.funcaoNome = symTab[t->item1]->identifier;                    
                    listProgram.push_back(symTab[t->item1]->identifier);
                    listProgram.push_back("][params");
                    PrintTree(t->second);
                    p_funcoes.size = cArgs;
                   // cout<<"parametro "<<p_funcoes.size<<endl;
                    funcoes_param.push_back(p_funcoes);
                    //funcoes.push_back(funcoes_param);
                    cArgs = 0;
                    //funcoes_param.clear();
                    listProgram.push_back("]");
                    PrintTree(t->third);
                    listProgram.push_back("]");

                    //salva o nome da funcao que usou return;
                    if (returnExp){funcReturn.push_back(symTab[t->item1]->identifier);}
                    if (returnEmp){funcRemp.push_back(symTab[t->item1]->identifier);}
                    //salva o nome das funcoes
                    listFuncName.push_back(symTab[t->item1]->identifier);
                     
                    //cout<<returnExp<<endl;
                    if (verificaReturn && !returnExp){
                        cout<<"funcao inteira "<<symTab[t->item1]->identifier <<" nao possui return exp"<<endl;
                        //exit(0);
                    }
                    verArgumentos.push_front(salvaParamFuncao);
                    verifyFuncao(verArgumentos,funcReturn,funcRemp,callReturn,listCall,listFuncInt,callOperation);
                    
                    escopo.pop_front();
                    salvaParamFuncao.clear();
                    declareLocais.clear();
                    declareArrayLocais.clear();
                    idVars.clear();
                    vetVars.clear();
                    argVars.clear();
                    listCall.clear();
                    callOperation.clear();
                    funcReturn.clear();
                    funcRemp.clear();
                    callReturn.clear();
                    verificaGlobal = true;
                }else {
                    cout<<"Funcao declarada apos o \"void main(void)\" "<<endl;
                }    
                return;
            break;

            case PARAMSLIST:
                // cout<<listVerificaMain.size()<<endl;
                if (verificaMain<=2){
                    verificaMain = 0;
                }
               
            break;

            case PARAMSVOID:
                if (verificaMain==2){ //verifica se o parametro e void
                    verificaMain ++ ;
                    verificaUltimaFuncao = true;
                }
                return;
            break;

            case IDPARAM:
                salvaParamFuncao.push_back("normal");
                listProgram.push_back("[param ");
                listProgram.push_back("[");
                
                PrintTree(t->first);
                
                listProgram.push_back("]");      
                listProgram.push_back("[");

                p_funcoes.nome[cArgs] = symTab[t->item1]->identifier;
                p_funcoes.tipo[cArgs] = "normal";
                cArgs++;
                //salva em variaveis locais
                declareLocais.push_back(symTab[t->item1]->identifier);
                if (declaracoes.find(symTab[t->item1]->identifier) == declaracoes.end()){
                    declaracoes.insert(pair<string,string>(symTab[t->item1]->identifier,"normal"));
                }else{
                    cout<<"overload do parametro \""<<symTab[t->item1]->identifier<<"\""<<endl;
                    exit(0);
                }
                listProgram.push_back(symTab[t->item1]->identifier);
                listProgram.push_back("]]");

                 //salva o nome da variavel em uma lista geral para verificar com o nome das funcoes
                // listNomesVariaveis.push_back(symTab[t->item1]->identifier);
                return;
            break;

            case VETORPARAM:
                salvaParamFuncao.push_back("vetor");
                listProgram.push_back("[param ");
                listProgram.push_back("[");
                PrintTree(t->first);
                listProgram.push_back("]");
                listProgram.push_back("[");

                p_funcoes.nome[cArgs] = symTab[t->item1]->identifier;
                p_funcoes.tipo[cArgs] = "vetor";
                cArgs++;

                //salva em variaveis locais
                if (declaracoes.find(symTab[t->item1]->identifier) == declaracoes.end()){
                    declaracoes.insert(pair<string,string>(symTab[t->item1]->identifier,"vetor"));
                }else{
                    cout<<"overload do parametro \""<<symTab[t->item1]->identifier<<"\""<<endl;
                    exit(0);
                }
                declareArrayLocais.push_back(symTab[t->item1]->identifier);
                listProgram.push_back(symTab[t->item1]->identifier);
                listProgram.push_back("]");
                listProgram.push_back("[\\[\\]]]");

                //  //salva o nome da variavel em uma lista geral para verificar com o nome das funcoes
                // listNomesVariaveis.push_back(symTab[t->item1]->identifier);
                return;
            break;

            case COMPOUNDSTMT:
               
                verifyEscopo(escopo,declareGlobais,declareArrayGlobais,
                declareArrayLocais,declareLocais,idVars,vetVars,argVars,
                declaracoes,variaveis);
                escopo.push_front(declaracoes);
                //declaracoes.clear();
                args.clear(); 
                listProgram.push_back("[");
                listProgram.push_back("compound-stmt");
                
                PrintTree(t->first);

                verifyEscopo(escopo,declareGlobais,declareArrayGlobais,
                declareArrayLocais,declareLocais,idVars,vetVars,argVars,
                declaracoes,variaveis);
                escopo.push_front(declaracoes);
                declaracoes.clear();
                args.clear(); 
                
                PrintTree(t->second);

                verifyEscopo(escopo,declareGlobais,declareArrayGlobais,
                declareArrayLocais,declareLocais,idVars,vetVars,argVars,
                declaracoes,variaveis);
                escopo.push_front(declaracoes); 
                listProgram.push_back("]");
                           
                escopo.pop_front();
                escopo.pop_front();
                escopo.pop_front();
                declaracoes.clear();
                variaveis.clear();
                args.clear();     
                                    
                return;
            break;

            case EMPEXSTMT:
                listProgram.push_back("[;]");
                return;
            break;

            case IFSELECTIONSTMT:
               
                listProgram.push_back("[selection-stmt ");
                expCall = true;
                PrintTree(t->first);
                expCall = false; 
                PrintTree(t->second);
                listProgram.push_back("]");
               
                return;
            break;

            case ELSESELECTIONSTMT:
                listProgram.push_back("[selection-stmt ");
                expCall = true;
                PrintTree(t->first);
                expCall = false;
                

                PrintTree(t->second);
                
                PrintTree(t->third);

                listProgram.push_back("]");
                
                
                return;
            break;

            case ITERATIONSTMT:
                listProgram.push_back("[iteration-stmt ");
                expCall = true;
                PrintTree(t->first);
                expCall = false;
                PrintTree(t->second);
                listProgram.push_back("]");
                
                return;
            break;

            case RETURNSTMTEMP:
                returnEmp = true;
                listProgram.push_back("[return-stmt]");
                return;
            break;

            case RETURNSTMTEXP:
                returnExp = true;
                listProgram.push_back("[return-stmt ");
                expCall = true;
                PrintTree(t->first);
                expCall = false;
                listProgram.push_back("]");
                return;
            break;

            case EQUALSEXPRESSION:
                operacao = true;
                if (estouEmArgs){
                    //cout<<"contei "<<cArgs<<endl;
                    compArgs++;
                }
                listProgram.push_back("[=");
                listProgram.push_back("[var ");
                PrintTree(t->first);
                listProgram.push_back("]");
                PrintTree(t->second);
                listProgram.push_back("]");
		        operacao = false;
                return;    
            break; 

            case OTHEREXPRESSION: 
                
                if (estouEmArgs){
                    //cout<<"contei "<<cArgs<<endl;
                    compArgs++;
                }
                
            break;

            case IDVAR :
                listProgram.push_back("[");
                listProgram.push_back(symTab[t->item1]->identifier);
                listProgram.push_back("]");
                if (verificaArgs.size() == 0){
                    idVars.push_back(symTab[t->item1]->identifier);
                    variaveis.insert(pair<string,string>(symTab[t->item1]->identifier,"normal"));
                }else{
                    argVars.push_back(symTab[t->item1]->identifier);
                    //cout<<"cargs"<<cArgs<<endl;
                    p_types.nome[cArgs] = symTab[t->item1]->identifier;
                    p_types.tipo[cArgs] ="neutro";
                    cArgs++; 
                    d_args.nome = symTab[t->item1]->identifier;
                    d_args.tipo = "neutro";
                    if (operacao){
                        d_args.podeOberacao = false;
                    }else{
                        d_args.podeOberacao = true;
                    }
                    dclArgs.push_back(d_args);
                    comparaArgs.push_back(symTab[t->item1]->identifier);
                }

                return;
            break;

            case VETORVAR:
                listProgram.push_back("[");
                listProgram.push_back(symTab[t->item1]->identifier);
                listProgram.push_back("]");
               if (estouEmArgs){
                    //cout<<"contei "<<cArgs<<endl;
                    compArgs--;
                }
                if (verificaArgs.size() == 0){
                    vetVars.push_back(symTab[t->item1]->identifier);
                    variaveis.insert(pair<string,string>(symTab[t->item1]->identifier,"vetor"));
                    
                }else{
                    argVars.push_back(symTab[t->item1]->identifier);
                    //cout<<"cargs"<<cArgs<<endl;
                    p_types.nome[cArgs] = symTab[t->item1]->identifier;
                    p_types.tipo[cArgs] ="neutro"; 
                    cArgs++;
                    d_args.nome = symTab[t->item1]->identifier;
                    d_args.tipo = "normal";
                    if (operacao){
                        d_args.podeOberacao = false;
                    }else{
                        d_args.podeOberacao = true;
                    }
                    dclArgs.push_back(d_args);
                    comparaArgs.push_back(symTab[t->item1]->identifier);
                }  
		        operacao = true;              
                PrintTree(t->first);
                operacao = false;
                return; 
            break;

            case TWOSIMPLEEXPRESSION:
                operacao = true;
                //cout<<operacao<<endl;
                listProgram.push_back("[");
                PrintTree(t->second);
                PrintTree(t->first);
                PrintTree(t->third);
                operacao = false;
                listProgram.push_back("]");
                return;
            break;
            
            case RELOP:
                
                if(t->item1 == LE_OP){
                    listProgram.push_back("<=");
                }else if(t->item1 == '<'){
                    listProgram.push_back("<");
                }else if(t->item1 == '>'){
                    listProgram.push_back(">");
                }else if(t->item1 == GE_OP){
                    listProgram.push_back(">=");
                }else if(t->item1 == EQ_OP){
                    listProgram.push_back("==");
                }else if(t->item1 == NE_OP){
                    listProgram.push_back("!=");
                }
                return;
            break;

            case TWOADDITIVEEXPRESSION:
                operacao = true;
                //cout<<"+ ou - "<<operacao<<endl;
                listProgram.push_back("[");
                PrintTree(t->second);
                PrintTree(t->first);
                PrintTree(t->third);
		        operacao = false;
                listProgram.push_back("]");
                return;
            break;

            case ADDOP:
                
                if(t->item1 == PLUS){
                    listProgram.push_back("+");
                }else if(t->item1 == MINUS){
                    listProgram.push_back("-");
                }    
                return;
            break;

            case TWOTERM:
                operacao = true;
                //cout<<"* ou / "<<operacao<<endl;
                listProgram.push_back("[");
                PrintTree(t->second);
                PrintTree(t->first);
                PrintTree(t->third);
                listProgram.push_back("]");
		        operacao = false;
                return;
            break;

            case MULOP:
                if(t->item1 == TIMES){
                    listProgram.push_back("*");
                }else if(t->item1 == DIVIDE){
                    listProgram.push_back("/");
                }    
                return;
            break;

            case VARFACTOR:
                
                listProgram.push_back("[var ");
                PrintTree(t->first);
                listProgram.push_back("]");
                //operacao = false;
                return;
            break;

            case CALLFACTOR:
                listProgram.push_back("[call ");
                if(comparaArgs.size()> 1 ){
                    p_types.tipo[compArgs] = "normal";
                    p_types.nome[compArgs] = "funcao";
                    
                    p_types.size = compArgs;
                    args.push_back(p_types);
                    argumentos.push_back(args);
                    verifyArgsFunc(escopo,verificaArgs,dclArgs,funcoes_param,argumentos,comparaArgs,deepFun);
                    //compArgs = 0;
                    comparaArgs.clear();
                    dclArgs.clear();
                    args.clear();
                    argumentos.pop_back();
                    
                }
                    
                deepFun++;                
                verificaArgs.push_front(true);
                //cout<<"Antes "<<compArgs<<endl;

                estouEmArgs = true;
                PrintTree(t->first);
                estouEmArgs = false;
                
                //cout<<"Depois "<<compArgs<<endl;
                verificaArgs.pop_front();  
                p_types.size = compArgs;
                //cout<<"Nome "<<p_types.funcaoNome<<" tamanho "<<p_types.size<<endl;
                if(p_types.funcaoNome == "input" && p_types.size > 0){
                    cout<<"input e do tipo void, nao pode ter argumento"<<endl;
                    exit(0);
                }
                if(p_types.funcaoNome == "println" && p_types.size != 1){
                    
                    cout<<"println tem que ter apenas 1 argumento"<<endl;
                    exit(0);
                        
                }
                args.push_back(p_types);
                //cout<<" argumento "<<p_types.size<<endl;
                if(p_types.funcaoNome != "println" && p_types.funcaoNome != "input" && deepFun == 1){
                    for (list<PARAM_TYPES>::iterator it=args.begin(); it!=args.end() ; ++it){
                        for (list<PARAM_TYPES>::iterator xt=funcoes_param.begin(); xt!=funcoes_param.end() ; ++xt){
                            if(it->funcaoNome ==xt->funcaoNome){
                                if(it->size==xt->size){
                                    verify = true;
                                }
                            }
                        }    
                    }
                    if (!verify){
                        cout<<"ERRO SEMANTICO - qnt de argumentos incompativel"<<endl;     
                        exit(0);
                    }
                }
                

                argumentos.push_back(args);
                verifyArgsFunc(escopo,verificaArgs,dclArgs,funcoes_param,argumentos,comparaArgs,deepFun);
                
                argumentos.pop_back();
                cArgs = 0;
                compArgs = 0;
                comparaArgs.clear();
                dclArgs.clear();
                args.clear();
                listProgram.push_back("]");
                return;
            break;

            case NUMFACTOR:
                //cout<<t->item1<<endl;
                if (t->item1 >=2147483648 || t->item1<=-2147483648){
                    cout<<"ERRO SEMANTICO - tamanho extrapola inteiro"<<endl;
                    exit(0);
                }   
                convert << t->item1; 
                listProgram.push_back("[");
                listProgram.push_back(convert.str());
                listProgram.push_back("]");

                if (verificaArgs.size() > 0){
                    //cout<<"cargs"<<cArgs<<endl;
                    p_types.tipo[cArgs] = "NUMBER";
                    p_types.nome[cArgs] = convert.str();
                    cArgs++;
                    d_args.nome = convert.str();;
                    d_args.tipo = "NUMBER";
                    if (operacao){
                        d_args.podeOberacao = false;
                    }else{
                        d_args.podeOberacao = true;
                    }
                    dclArgs.push_back(d_args);
                    comparaArgs.push_back(convert.str());
                }
                convert.str("");
               // operacao = false;
                return;
            break;

            case CALL:
                listProgram.push_back("[");
                listProgram.push_back(symTab[t->item1]->identifier);
                //guarda o nome da funcao chamada
                listCall.push_back(symTab[t->item1]->identifier);
                p_types.funcaoNome = symTab[t->item1]->identifier;
                /*VERIFICA SE UMA FUNCAO DENTRO DE UMA FUNCAO E INTEIRA ou nao existe*/
                bool verificador;
                if(verificaArgs.size()>1){
                    for(list<string>::iterator it=listFuncInt.begin(); it!=listFuncInt.end() ; ++it){
                        if (*it == symTab[t->item1]->identifier){
                        verificador = true;
                        }
                    }
                    if (verificador == false){
                        cout<<"ERRO SEMANTICO - funcao "<< symTab[t->item1]->identifier <<" nao é inteira ou nao existe."<<endl;
                        exit(0);
                    }
                }
                /*FIM*/

                if(operacao){
                    callOperation.push_back(symTab[t->item1]->identifier);
                }
                operacao = false;
                if(expCall){
                    callReturn.push_back(symTab[t->item1]->identifier);
                }
                listProgram.push_back("]");
                listProgram.push_back("[args ");
                PrintTree(t->first);
                listProgram.push_back("]");
                return;
            break; 
            
        }
    
    PrintTree(t->first);
    PrintTree(t->second);
    PrintTree(t->third);
}

void semanticVerify(list<string>listFuncName,list<string>listDecVar,
    int verificaMain, list<string>listNomesVariaveis,list<string>listProgram){
    
    //VERIFICA PRESENCA DO VOID MAIN(VOID) --COMPLETO
    
    if (!verificaUltimaFuncao){
        cout<<"ERRO SEMANTICO - codigo nao possui \"void main(void)\""<<endl;
        exit(0);
    }


    //VERIFICA OVERLOAD DE FUNCOES --COMPLETO
    string s[listFuncName.size()];
    int i = 0;
    for (list<string>::iterator it=listFuncName.begin(); it!=listFuncName.end() ; ++it){
        s[i] = *it;
        i++;
    }    

    for (list<string>::iterator it=listFuncName.begin(); it!=listFuncName.end() ; ++it){
        int contador = 0;
        for (int i = 0; i<listFuncName.size();i++){
            if (*it == s[i]){
                 contador ++;
            }
        }
        if (contador>1){
            cout<<"ERRO SEMANTICO - Overload de funcao()"<<endl;
            exit(0);
        }
    }        
        
    //INTERROMPE CASO ALGUMA VARIAVEL TENHA SIDO DECLARADA COMO VOID -- COMPLETO
    //porem nao verifica caso isso seja feito no parametro da funcao
    for (list<string>::iterator it=listDecVar.begin(); it!=listDecVar.end() ; ++it){
       if (*it == "void"){
           cout<<"ERRO SEMANTICO - Variavel declarada como void"<<endl;
           exit(0);
       }
    }

    //verifica se nenhuma variavel declarada tem nome de funcao -- COMPLETO
    int y = 0;
    string todasVariaveis[listNomesVariaveis.size()];
    for (list<string>::iterator it=listNomesVariaveis.begin(); it!=listNomesVariaveis.end() ; ++it){
        todasVariaveis[y] = *it;
        y++;
    }

    for (int i = 0; i<listNomesVariaveis.size();i++){
        int contador = 0;
        for(list<string>::iterator it=listFuncName.begin(); it!=listFuncName.end() ; ++it){
            if (*it == todasVariaveis[i]){
                contador++;
            }
        }
        if (contador > 0){
            cout<<"ERRO SEMANTICO - variavel e funcao "<< todasVariaveis[i]<<" usando o mesmo nome."<<endl;
            exit(0);
        }
    }
    
}

void verifyEscopo(ESCOPO,list<string>declareGlobais, list<string>declareArrayGlobais, list<string>declareArrayLocais,
    list<string>declareLocais, list<string>idVars, list<string>vetVars,list<string>argVars,map<string,string>declaracoes,
    map<string,string>variaveis){

    bool verificador = false;

    //verifica se a variavel ja foi declarada
    for (map<string,string>::iterator var = variaveis.begin();var!=variaveis.end();var++){
        verificador = false;
        //cout<<" "<<var->first<<endl;
        for (ESCOPO::iterator itr = escopo.begin();itr!=escopo.end();itr++){
            for (map<string,string>::iterator decl = itr->begin();decl!=itr->end();decl++){
                if(var->first == decl->first){
                    if(var->second == decl->second)
                        verificador = true;
                }
            }       
        }
        if (verificador == false){
            cout<<"Variavel "<<var->first<< " nao declarada"<<endl;
            exit(0);
        }
    }
    //cout<<endl;
}

void verifyArgsFunc(ESCOPO escopo ,list<bool>verificaArgs,list<DECLARED_ARGS>dclArgs,list<PARAM_TYPES>funcoes_param,
    list<list<PARAM_TYPES> >argumentos,list<string> comparaArgs,int deepFun){
  
    bool verificador;
    //verifica se os argumentos usados nas funcoes ja foram declarados
    for (list<DECLARED_ARGS>::iterator argumento = dclArgs.begin();argumento!= dclArgs.end(); argumento++){
        verificador = false;
        for (ESCOPO::iterator itr = escopo.begin();itr!=escopo.end();itr++){
            for (map<string,string>::iterator decl = itr->begin();decl!=itr->end();decl++){
                if(argumento->nome == decl->first){
                    if(argumento->tipo!="normal"){
                        argumento->tipo = decl->second;
                    }    
                    verificador = true;
                    if(argumento->tipo == "vetor" && !argumento->podeOberacao){
                         cout<<"Vetor "<<argumento->nome<< " nao declarado pode fazer operacao"<<endl;
                         exit(0);
                    }    
                }    
            }
        }       
        
        if (verificador == false && argumento->tipo !="NUMBER"){
            cout<<"argumento "<<argumento->nome<< " nao declarado"<<endl;
            exit(0);
        }
    }
    
    
    //passa o tipo dos argumentos para a tabSym que ira fazer as comparacoes.
    for (list<list<PARAM_TYPES> >::iterator itr = argumentos.begin();itr!=argumentos.end();itr++){
        for (list<PARAM_TYPES>::iterator decl = itr->begin();decl!=itr->end();decl++){
            //cout<<decl->funcaoNome<<" "<<decl->size<<endl;
            for(int i = 0; i<decl->size; i++){
                for (list<DECLARED_ARGS>::iterator argumento = dclArgs.begin();argumento!= dclArgs.end();argumento++){
                    if (decl->nome[i] == argumento->nome){
                        decl->tipo[i] = argumento->tipo;
                        if (decl->funcaoNome =="println" && decl->tipo[i]=="vetor"){
                            cout<<"println so pode receber inteiro"<<endl;
                            exit(0);
                        }
                        // cout<<decl->nome[i]<<" "<<decl->tipo[i]<<" "<<endl;                            
                    }
                }
            }
        }
        //cout<<endl; 
    }
    //compara tamanho e tipo com a original.

    if(deepFun == 1){
        for (list<list<PARAM_TYPES> >::iterator itr = argumentos.begin();itr!=argumentos.end();itr++){
            for (list<PARAM_TYPES>::iterator decl = itr->begin();decl!=itr->end();decl++){
                for (list<PARAM_TYPES>::iterator func = funcoes_param.begin();func!=funcoes_param.end();func++){
                    for(int i = 0;i<decl->size;i++){
                        if (decl->tipo[i] == "NUMBER"){
                            decl->tipo[i] = "normal";
                        }
                        if(func->tipo[i]!=decl->tipo[i]){
                            cout<<"incompatibilidade de tipos"<<endl;
                            exit(0);
                        }
                        //cout<<func->tipo[i]<<" "<<decl->tipo[i]<<" "<<endl;
                    }
                }    
            }
        }
    }       


} 

void verifyFuncao(list<list<string> >verArgumentos,list<string>funcReturn,list<string>funcRemp,list<string>callReturn,list<string>listCall,list<string>listFuncInt,
    list<string>callOperation){
    //verifica se uma funcao chamada ja foi declarada anteriormente--COMPLETO
    bool verificador;
    string nomeFuncao[listFuncName.size()];
    int g = 0;

    for (list<string>::iterator it = listFuncName.begin(); it!=listFuncName.end();++it){
        nomeFuncao[g] = *it;
        g++;
    }
    for (list<string>::iterator it=listCall.begin(); it!=listCall.end() ; ++it){
        verificador  = false;
        for (int i = 0; i<listFuncName.size();i++){
            if (*it == nomeFuncao[i]){
                 verificador  = true;
            }
        }
        if (verificador == false){
            cout<<"ERRO SEMANTICO - funcao chamada "<<*it<<" nao existe"<<endl;
            exit(0);
        }
    }

    //verifica se a funcao chamada é do tipo Int --COMPLETO
    string callFunc[callOperation.size()];
    int f = 0;

    for (list<string>::iterator it = callOperation.begin(); it!=callOperation.end();++it){
        //cout<<*it<<endl;
        callFunc[f] = *it;
        f++;
    }

    for (int i = 0; i < callOperation.size();i++){
        verificador = false;
        for(list<string>::iterator it=listFuncInt.begin(); it!=listFuncInt.end() ; ++it){
            if (*it == callFunc[i]){
                verificador = true;
            }
        }
        if (verificador == false){
            cout<<"ERRO SEMANTICO - funcao "<< callFunc[i] <<" nao é inteira."<<endl;
            exit(0);
        }
    }
    
    //verifica se o return exp foi chamada em uma funcao inteira.
    string rExp[funcReturn.size()];
    int t = 0;

    for (list<string>::iterator it = funcReturn.begin(); it!=funcReturn.end();++it){
        //cout<<*it<<endl;
        rExp[t] = *it;
        t++;
    }

    for (int i = 0; i < funcReturn.size();i++){
        verificador = false;
        for(list<string>::iterator it=listFuncInt.begin(); it!=listFuncInt.end() ; ++it){
            if (*it == rExp[i]){
                verificador = true;
            }
        }
        if (verificador == false){
            cout<<"ERRO SEMANTICO - funcao "<< rExp[i] <<" nao pode ter return expression."<<endl;
            exit(0);
        }
    }
    //caso o return seja de uma funcao, verifica se essa funcao é do tipo inteira
    string rFuncao[callReturn.size()];
    t = 0;

    for (list<string>::iterator it = callReturn.begin(); it!=callReturn.end();++it){
        //cout<<*it<<endl;
        rFuncao[t] = *it;
        t++;
    }

    for (int i = 0; i < callReturn.size();i++){
        verificador = false;
        for(list<string>::iterator it=listFuncInt.begin(); it!=listFuncInt.end() ; ++it){
            if (*it == rFuncao[i]){
                verificador = true;
            }
        }
        if (verificador == false){
            cout<<"ERRO SEMANTICO - funcao "<< rFuncao[i] <<" nao é inteira."<<endl;
            exit(0);
        }
    }


    //verifica se o return ; foi usado em uma funcao void.
    string rEmp[funcRemp.size()];
    t = 0;

    for (list<string>::iterator it = funcRemp.begin(); it!=funcRemp.end();++it){
        //cout<<*it<<endl;
        rEmp[t] = *it;
        t++;
    }

    for (int i = 0; i < funcRemp.size();i++){
        for(list<string>::iterator it=listFuncInt.begin(); it!=listFuncInt.end() ; ++it){
            if (*it == rEmp[i]){
                cout<<"ERRO SEMANTICO - funcao "<< rEmp[i] <<" nao pode ter return;."<<endl;
                exit(0);
            }
        }
    }
}

int main(int argc, char *argv[]){
    FILE *parseFile = fopen(argv[1],"r"); 	
    yyin = parseFile;
 	nomeDoArquivo = argv[2];
   saida.open(argv[2]);/* = fopen(argv[2],"w");*/  
   do {
		yyparse();
	} while (!feof(yyin));
	
 }

void yyerror(const char *s)
 {
 	fflush(stdout);
 	//fprintf(saida,"*** %s\n", s);
    printf("ERRO SINTATICO, AMIIIGOOOOOO!!! %s\n", s);
    saida.close();
    saida.open(nomeDoArquivo, std::ofstream::out | std::ofstream::trunc);
    saida.close();
    // saida<<"";
    exit(-1);
 }

#include "lex.yy.c"

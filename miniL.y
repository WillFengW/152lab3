    /* cs152-miniL phase2 */
%{
  #define YY_NO_UNPUT
  #include <stdio.h>
  #include <stdlib.h>
  #include <map>
  #include <string.h>
  #include <set>
  using namespace std;

  int tempCount = 0;
  int labelCount = 0;
  extern char* yytext;
  map<string, string> varTemp;
  map<string, int> arrSize;
  bool mainFunc = false;
  set<string> funcs;
  set<string> reserved {"NUMBER", "IDENT", "FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", 
  "END_BODY", "INTEGER", "ARRAY", "ENUM", "OF", "IF", "THEN", "ENDIF", "ELSE", "WHILE", "FOR", "DO", 
  "BEGINLOOP", "ENDLOOP", "CONTINUE", "READ", "WRITE", "TRUE", "FALSE",
  "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "ASSIGN", "RETURN",
  "Function", "Declaration", "Declarations", "Identifiers", "Ident", "Statement", "Statements", "Vars", "Bool_expr",
  "Relation_expr", "Relation_expr_inv", "Relation_and_expr", ",Multiplicative_expr", "Comp", "Expression", "Expressions", "Term", "Var"}


  void yyerror(const char *msg);
  extern int currPos;
  int yylex();
  string new_temp();
  string new_lebal();
%}

%union{
  /* put your types here */
  int numVal;
  char * identVal;
  struct S {
    char* code;
  } statement;

  struct E {
    char* place;
    char* code;
    bool arr;
  } expression;
}

%start Program

%token <identVal> IDENT
%token <numVal> NUMBER

%type <expression> Function Declaration Declarations Identifiers Ident Vars Var
%type <expression> Bool_expr Relation_expr_inv Relation_expr Relation_and_expr Multiplicative_expr Comp Expression Expressions Term
%type <statement> Statement Statements

%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE FOR DO BEGINLOOP ENDLOOP CONTINUE READ WRITE TRUE FALSE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN RETURN

%right ASSIGN
%left OR
%left AND
%right NOT
%left LT LTE GT GTE EQ NEQ
%left ADD SUB
%left MULT DIV MOD

/* %start program */

%% 

  /* write your rules here */

Program:        %empty
        {
                if (!mainFunc) {
                    printf("No main function declared!\n");
                }
        }
        |       Function Program
        {
        }
        ;

Function:         FUNCTION Ident SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY
                  { printf("function -> FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY\n"); }   
        ;
      
Declarations:     /*empty*/ { printf("declarations -> epsilon\n"); }
        |         Declaration SEMICOLON Declarations {printf("declarations -> declaration SEMICOLON declarations\n"); }
        ;

Declaration:      Identifiers COLON INTEGER { printf("declaration -> identifiers COLON INTEGER\n"); }
        |         Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
                  { printf("declaration -> identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER %d R_SQUARE_BRACKET OF INTEGER\n", $5); }
        |         Identifiers COLON ENUM L_PAREN Identifiers R_PAREN
                  { printf("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n"); }
        ;

Identifiers:      Ident { printf("identifiers -> ident\n"); }
        |         Ident COMMA Identifiers { printf("identifiers -> ident COMMA identifiers\n"); }
        ;

Ident:            IDENT { printf("ident -> IDENT %s\n", $1); }
        ;

Statements:       /*empty*/ { printf("statements -> epsilon\n"); }
        |         Statement SEMICOLON Statements { printf("statements -> statement SEMICOLON statements\n"); }
        ;

Statement:        Var ASSIGN Expression { printf("statement -> var ASSIGN expression\n"); }
        |         IF Bool_expr THEN Statements ENDIF { printf("statement -> IF bool_expr THEN statements ENDIF\n"); }
        |         IF Bool_expr THEN Statements ELSE Statements ENDIF { printf("statement -> IF bool_expr THEN statements ELSE statements ENDIF\n"); }
        |         WHILE Bool_expr BEGINLOOP Statements ENDLOOP { printf("statement -> WHILE bool_expr BEGINLOOP statements ENDLOOP\n"); }
        |         DO BEGINLOOP Statements ENDLOOP WHILE Bool_expr { printf("statement -> DO BEGINLOOP statements ENDLOOP WHILE bool_expr\n"); }
        |         READ Vars { printf("statement -> READ vars\n"); }
        |         WRITE Vars { printf("statement -> WRITE vars\n"); }
        |         CONTINUE { printf("statement -> CONTINUE\n"); }
        |         RETURN Expression { printf("statement -> RETURN expression\n"); }
        ;

Vars:             Var 
        {         string temp;
                  temp.append($1.code);
                  if ($1.arr) {
                      temp.append(".[]| ");
                  } else {
                      temp.append(".| ");
                  }
                  temp.append($1.place);
                  temp.append("\n");
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
        }
        |         Var COMMA Vars 
        {         string temp;
                  temp.append($1.code);
                  if ($1.arr) {
                      temp.append(".[]| ");
                  } else {
                      temp.append(".| ");
                  }
                  temp.append($1.place);
                  temp.append("\n");
                  temp.append($3.code);
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
        }
        ;

Bool_expr:        Relation_and_expr 
        {         $$.code = strdup($1.code);
                  $$.place = strdup($1.place);
        }
        |         Relation_and_expr OR Bool_expr 
        {         string temp;
                  string dst = new_temp();
                  temp.append($1.code);
                  temp.append($3.code);
                  temp += ". " + dst + "\n";
                  temp += "|| " + dst + ", ";
                  temp.append($1.place);
                  temp.append(", ");
                  temp.append($3.place);
                  temp.append("\n");
                  $$.code = strdup(temp.c_str());
                   $$.place = strdup(dst.c_str());
        }
        ;

Relation_and_expr:	      Relation_expr_inv 
        {                 $$.code = strdup($1.code);
                          $$.place = strdup($1.place);
        }
        |                 Relation_expr_inv AND Relation_and_expr 
        {                 string temp;
                          string dst = new_temp();
                          temp.append($1.code);
                          temp.append($3.code);
                          temp += ". " + dst + "\n";
                          temp += "&& " + dst + ", ";
                          temp.append($1.place);
                          temp.append(", ");
                          temp.append($3.place);
                          temp.append("\n");
                          $$.code = strdup(temp.c_str());
                          $$.place = strdup(dst.c_str());
        }
        ;

Relation_expr_inv:    NOT Relation_expr_inv
        {             string temp;
                      string dst = new_temp();
                      temp.append($2.code);
                      temp += ". " + dst + "\n";
                      temp += "! " + dst + ", ";
                      temp.append($2.place);
                      temp.append("\n");
                      $$.code = strdup(temp.c_str());
                      $$.place = strdup(dst.c_str());
        }
        |
                      Relation_expr
        {             $$.code = strdup($1.code);
                      $$.place = strdup($1.place);
        }
        ;

Relation_expr:	      Expression Comp Expression 
        {             string dst = new_temp();
                      string temp;
                      temp.append($1.code);
                      temp.append($3.code);
                      temp = temp + ". " + dst + "\n" + $2.place + dst + ", " + $1.place + ", " + $3.place + "\n";
                      $$.code = strdup(temp.c_str());
                      $$.place = strdup(dst.c_str());
        }
        |             TRUE 
        {             string temp;
                      temp.append("1");
                      $$.code = strdup("");
                      $$.place = strdup(temp.c_str());
        }
	      |             FALSE 
        {             string temp;
                      temp.append("0");
                      $$.code = strdup("");
                      $$.place = strdup(temp.c_str());
        }
	      |             L_PAREN Bool_expr R_PAREN 
        {             $$.code = strdup($2.code);
                      $$.place = strdup($2.place);
        }
	      ;

Comp:		              EQ
        {             $$.code = strdup("");
                      $$.place = strdup("== ");
        }
	      |             NEQ 
        {             $$.code = strdup("");
                      $$.place = strdup("!= ");
        }
	      |             LT 
        {             $$.code = strdup("");
                      $$.place = strdup("< ");
        }
	      |             GT 
        {             $$.code = strdup("");
                      $$.place = strdup("> ");
        }
	      |             LTE 
        {             $$.code = strdup("");
                      $$.place = strdup("<= ");
        }
	      |             GTE 
        {             $$.code = strdup("");
                      $$.place = strdup(">= ");
        }
	      ;

Expression:           Multiplicative_expr 
        {             $$.code = strdup($1.code);
                      $$.place = strdup($1.place);
        }
        |             Multiplicative_expr ADD Expression
        {             string temp;
                      string dst = new_temp();
                      temp.append($1.code);
                      temp.append($3.code);
                      temp += ". " + dst + "\n";
                      temp += "+ " + dst + ", ";
                      temp.append($1.place);
                      temp += ", ";
                      temp.append($3.place);
                      temp += "\n";
                      $$.code = strdup(temp.c_str());
                      $$.place = strdup(dst.c_str());
        }
        |             EMultiplicative_expr SUB Expression
        {             string temp;
                      string dst = new_temp();
                      temp.append($1.code);
                      temp.append($3.code);
                      temp += ". " + dst + "\n";
                      temp += "- " + dst + ", ";
                      temp.append($1.place);
                      temp += ", ";
                      temp.append($3.place);
                      temp += "\n";
                      $$.code = strdup(temp.c_str());
                      $$.place = strdup(dst.c_str());
        }
        ;

Multiplicative_expr:	    Term  
        {             $$.code = strdup($1.code);
                      $$.place = strdup($1.place);
        }
        |                 Term MULT Multiplicative_expr
        {                 string temp;
                          string dst = new_temp();
                          temp.append($1.code);
                          temp.append($3.code);
                          temp.append(". ");
                          temp.append(dst);
                          temp.append("\n");
                          temp += "* " + dst + ", ";
                          temp.append($1.place);
                          temp += ", ";
                          temp.append($3.place);
                          temp += "\n";
                          $$.code = strdup(temp.c_str());
                          $$.place = strdup(dst.c_str());
        }
        |                 Term DIV Multiplicative_expr
        {                 string temp;
                          string dst = new_temp();
                          temp.append($1.code);
                          temp.append($3.code);
                          temp.append(". ");
                          temp.append(dst);
                          temp.append("\n");
                          temp += "/ " + dst + ", ";
                          temp.append($1.place);
                          temp += ", ";
                          temp.append($3.place);
                          temp += "\n";
                          $$.code = strdup(temp.c_str());
                          $$.place = strdup(dst.c_str()); 
        }
        |                 Term MOD Multiplicative_expr 
        {                 string temp;
                          string dst = new_temp();
                          temp.append($1.code);
                          temp.append($3.code);
                          temp.append(". ");
                          temp.append(dst);
                          temp.append("\n");
                          temp += "% " + dst + ", ";
                          temp.append($1.place);
                          temp += ", ";
                          temp.append($3.place);
                          temp += "\n";
                          $$.code = strdup(temp.c_str());
                          $$.place = strdup(dst.c_str()); 
        }
        ;

Term:		                Var 
        {               string dst = new_temp();
                        string temp;
                        if ($1.arr) {
                            temp.append($1.code);
                            temp.append(". ");
                            temp.append(dst);
                            temp.append("\n");
                            temp += "=[] " + dst + ", ";
                            temp.append($1.place);
                            temp.append("\n");
                        } else {
                            temp.append(". ");
                            temp.append(dst);
                            temp.append("\n");
                            temp = temp + "= " + dst + ", ";
                            temp.append($1.place);
                            temp.append("\n");
                            temp.append($1.code);
                        }
                        if (varTemp.find($1.place) != varTemp.end()) {
                            varTemp[$1.place] = dst;
                        }
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str()); 
        }
	      |               SUB Var 
        {               string dst = new_temp();
                        string temp;
                        if ($2.arr) {
                            temp.append($2.code);
                            temp.append(". ");
                            temp.append(dst);
                            temp.append("\n");
                            temp += "=[] " + dst + ", ";
                            temp.append($2.place);
                            temp.append("\n");
                        } else {
                            temp.append(". ");
                            temp.append(dst);
                            temp.append("\n");
                            temp = temp + "= " + dst + ", ";
                            temp.append($2.place);
                            temp.append("\n");
                            temp.append($2.code);
                        }
                        if (varTemp.find($2.place) != varTemp.end()) {
                            varTemp[$2.place] = dst;
                        }
                        temp += "* " + dst + ", " + dst + ", -1\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
        }
      	|               NUMBER 
        {               string dst = new_temp();
                        string temp;
                        temp.append(". ");
                        temp.append(dst);
                        temp.append("\n");
                        temp = temp + "= " + dst + ", " + to_string($1) + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
        }
      	|               SUB NUMBER 
        {               string dst = new_temp();
                        string temp;
                        temp.append(". ");
                        temp.append(dst);
                        temp.append("\n");
                        temp = temp + "= " + dst + ", -" + to_string($2) + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
        }
      	|               L_PAREN Expression R_PAREN 
        {               $$.code = strdup($2.code);
                        $$.place = strdup($2.place);
        }
	      |               SUB L_PAREN Expression R_PAREN 
        {               string temp;
                        temp.append($3.code);
                        temp.append("* ");
                        temp.append($3.place);
                        temp.append(", ");
                        temp.append($3.place);
                        temp.append(", -1\n");
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup($3.place);
        }
	      |               Ident L_PAREN Expressions R_PAREN 
        {               string temp;
                        string func = $1.place;
                        if (funcs.find(func) == funcs.end()) {
                            printf("Calling undeclared function %s.\n", func.c_str());
                        }
                        string dst = new_temp();
                        temp.append($3.code);
                        temp += ". " + dst + "\ncall ";
                        temp.append($1.place);
                        temp += ", " + dst + "\n";
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup(dst.c_str());
        }
	      ;

Expressions:            Expression 
        {               string temp;
                        temp.append($1.code);
                        temp.append("param ");
                        temp.append($1.place);
                        temp.append("\n");
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
        }
        |               Expression COMMA Expressions
        {               string temp;
                        temp.append($1.code);
                        temp.append("param ");
                        temp.append($1.place);
                        temp.append("\n");
                        temp.append($3.code);
                        $$.code = strdup(temp.c_str());
                        $$.place = strdup("");
        }
        ;

Var:		                Ident 
        {               string temp;
                        string ident = $1.place;
                        if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()) {
                            printf("Identifier %s is not declared.\n", ident.c_str());
                        } else if (arrSize[ident] > 1) {
                            printf("Did not provide index for array Identifier %s.\n", ident.c_str());
                        }      
                        $$.code = strdup("");
                        $$.place = strdup(ident.c_str());
                        $$.arr = false;    
        }
	      |               Ident L_SQUARE_BRACKET Expression R_SQUARE_BRACKET 
        {               string temp;
                        string ident = $1.place;
                        if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end()) {
                            printf("Identifier %s is not declared.\n", ident.c_str());
                        } else if (arrSize[ident] == 1) {
                            printf("Provided index for non-array Identifier %s.\n", ident.c_str());
                        }      
                        temp.append($1.place);
                        temp.append(", ");
                        temp.append($3.place);
                        $$.code = strdup($3.code);
                        $$.place = strdup(temp.c_str());
                        $$.arr = true;    
        }
	      ;

%% 

int main(int argc, char ** argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            printf("syntax: %s filename", argv[0]);
        }
    }
    yyparse();
    return 0;
}

void yyerror(const char *msg) {
    extern int yylineno;
    extern char *yytext;
    printf("%s on line %d at char %d at symbol \"%s\"\n", msg, yylineno, currPos, yytext);
    exit(1);
}

string new_temp() {
    string t = "t" + to_string(tempCount);
    tempCount++;
    return t;
}

string new_lebal() {
    string l = "L" + to_string(labelCount);
    labelCount++;
    return l;
}
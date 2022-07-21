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
  "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "ASSIGN", "RETURN", "Program", 
  "Function", "Declaration", "Declarations", "FuncIdent", "Identifiers", "Ident", "Statement", "EStatements", "Statements", "Vars", "Bool_expr",
  "Relation_expr", "Relation_expr_inv", "Relation_and_expr", ",Multiplicative_expr", "Comp", "Expression", "Expressions", "Term", "Var"};


  void yyerror(const char* msg);
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

%type <expression> Function Declaration Declarations Identifiers Ident Vars Var FuncIdent
%type <expression> Bool_expr Relation_expr_inv Relation_expr Relation_and_expr Multiplicative_expr Comp Expression Expressions Term
%type <statement> Statement Statements EStatements

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

Function:         FUNCTION FuncIdent SEMICOLON BEGIN_PARAMS Declarations END_PARAMS BEGIN_LOCALS Declarations END_LOCALS BEGIN_BODY Statements END_BODY
        {         string temp = "func ";
                  temp.append($2.place);
                  temp.append("\n");
                  string s = $2.place;
                  if (s == "main") {
                        mainFunc = true;
                  }
                  temp.append($5.code);
                  string decs = $5.code;
                  int decNum = 0;
                  while(decs.find(".") != string::npos) {
                        int pos = decs.find(".");
                        decs.replace(pos, 1, "=");
                        string part = ", $" + to_string(decNum) + "\n";
                        decNum++;
                        decs.replace(decs.find("\n", pos), 1, part);
                  }
                  temp.append(decs);
                  temp.append($8.code);
                  string statements = $11.code;
                  if (statements.find("continue") != string::npos) {
                        printf("ERROR: Continue outside loop in function %s\n", $2.place);
                  }
                  temp.append(statements);
                  temp.append("endfunc\n\n");
                  printf(temp.c_str());
        }   
        ;
      
Declarations:     %empty 
        {         $$.code = strdup("");
                  $$.place = strdup("");
        }
        |         Declaration SEMICOLON Declarations 
        {         string temp;
                  temp.append($1.code);
                  temp.append($3.code);
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
        }
        ;

Declaration:      Identifiers COLON INTEGER 
        {         string temp;
                  string ids($1.place);
                  string vars;
                  size_t pos1 = 0;
                  size_t pos2 = 0;
                  bool noLine = true;

                  while(noLine) {
                        pos1 = ids.find("|", pos2); // find first | start at pos2

                        if (pos1 == string::npos) {
                            temp.append(". ");
                            vars = ids.substr(pos2, pos1);
                            temp.append(vars);
                            temp.append("\n");
                            noLine = false;
                        } else {
                            size_t firstLine = pos1 - pos2; // find first |
                            temp.append(". ");
                            vars = ids.substr(pos2, firstLine); 
                            temp.append(vars);
                            temp.append("\n");
                        }
                        
                        pos2 = pos1 + 1; 
                  }
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
        }
        |         Identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
        {         string temp;
                  string ids($1.place);
                  string vars;
                  size_t pos1 = 0;
                  size_t pos2 = 0;
                  bool noLine = true;

                  while(noLine) {
                        pos1 = ids.find("|", pos2); // find first | start at pos2

                        if (pos1 == string::npos) {
                            temp.append(".[] ");
                            vars = ids.substr(pos2, pos1);
                            temp.append(vars);
                            temp.append(", ");
                            temp.append(to_string($5));
                            temp.append("\n");
                            noLine = false;
                        } else {
                            size_t firstLine = pos1 - pos2; // find first |
                            temp.append(".[] ");
                            vars = ids.substr(pos2, firstLine); 
                            temp.append(vars);
                            temp.append(", ");
                            temp.append(to_string($5));
                            temp.append("\n");
                        }
                        
                        pos2 = pos1 + 1; 
                  }
                  $$.code = strdup(temp.c_str());
                  $$.place = strdup("");
        }
        ;

Identifiers:      Ident 
        {         $$.place = strdup($1.place);
                  $$.code = strdup("");
        }
        |         Ident COMMA Identifiers 
        {         string temp;
                  temp.append($1.place);
                  temp.append("|");
                  temp.append($3.place);
                  $$.place = strdup(temp.c_str());
                  $$.code = strdup("");
        }
        ;

FuncIdent:        IDENT
        {         if (funcs.find($1) != funcs.end()) {
                        printf("function name %s already declared.\n", $1);
                  } else {
                        funcs.insert($1);
                  }
                  $$.place = strdup($1);
                  $$.code = strdup("");
        }
        ;

Ident:            IDENT 
        {         $$.place = strdup($1);
                  $$.code = strdup("");
        }
        ;

Statements:       Statement SEMICOLON 
        {         $$.code = strdup($1.code);
        }
        |         Statement SEMICOLON Statements 
        {         string temp;
                  temp.append($1.code);
                  temp.append($3.code);
                  $$.code = strdup(temp.c_str());
        }
        ;

Statement:        Var ASSIGN Expression
        {         string temp;
                  temp.append($1.code);
                  temp.append($3.code);
                  string dst = new_temp();

                  if ($1.arr) {
                        temp.append("[]= ");
                  } else if ($3.arr) {
                        temp.append("=[] ");
                  } else {
                        temp.append("= ");
                  }
                  temp.append($1.place);
                  temp.append(", ");
                  temp.append($3.place);
                  temp.append("\n");
                  $$.code = strdup(temp.c_str());
        }
        |         IF Bool_expr THEN Statements EStatements ENDIF 
        {         string temp;
                  string then = new_lebal();
                  string go = new_lebal();

                  temp.append($2.code);
                  temp.append("?:= ");
                  temp.append(then);
                  temp.append(", ");
                  temp.append($2.place);
                  temp.append("\n");
                  temp.append($5.code);
                  temp.append(":= ");
                  temp.append(go);
                  temp.append("\n");
                  temp.append(": ");
                  temp.append(then);
                  temp.append("\n");
                  temp.append($4.code);
                  temp.append(": ");
                  temp.append(go);
                  temp.append("\n");

                  $$.code = strdup(temp.c_str());
        }
        |         WHILE Bool_expr BEGINLOOP Statements ENDLOOP 
        {         string temp;
                  string beginWhile = new_lebal();
                  string beginLoop = new_lebal();
                  string endLoop = new_lebal();
                
                  string statement = $4.code;
                  string go;
                  go.append(":= ");
                  go.append(beginWhile);
                  while (statement.find("continue") != string::npos) {
                      statement.replace(statement.find("continue"), 8, go);
                  }
                
                  temp.append(": ");
                  temp.append(beginWhile);
                  temp.append("\n");
                  temp.append($2.code);
                  temp.append("?:= ");
                  temp.append(beginLoop);
                  temp.append(", ");
                  temp.append($2.place);
                  temp.append("\n");
                  temp.append(":= ");
                  temp.append(endLoop);
                  temp.append("\n");
                  temp.append(": ");
                  temp.append(beginLoop);
                  temp.append("\n");
                  temp.append(statement);
                  temp.append(":= ");
                  temp.append(beginWhile);
                  temp.append("\n");
                  temp.append(": ");
                  temp.append(endLoop);
                  temp.append("\n");

                  $$.code = strdup(temp.c_str());
        }
        |         DO BEGINLOOP Statements ENDLOOP WHILE Bool_expr 
        {         string temp;
                  string beginWhile = new_lebal();
                  string beginLoop = new_lebal();
                
                  string statement = $3.code;
                  string go;
                  go.append(":= ");
                  go.append(beginWhile);
                  while (statement.find("continue") != string::npos) {
                      statement.replace(statement.find("continue"), 8, go);
                  }
                
                  temp.append(": ");
                  temp.append(beginLoop);
                  temp.append("\n");
                  temp.append(statement);
                  temp.append(": ");
                  temp.append(beginWhile);
                  temp.append("\n");
                  temp.append($6.code);
                  temp.append("?:= ");
                  temp.append(beginLoop);
                  temp.append(", ");
                  temp.append($6.place);
                  temp.append("\n");

                  $$.code = strdup(temp.c_str());
        }
        |         READ Vars 
        {         string temp;
                  temp.append($2.code);
                  size_t pos = temp.find("|", 0);
                  while(pos != string::npos) {
                        temp.replace(pos, 1, "<");
                        pos = temp.find("|", pos);
                  }
                  $$.code = strdup(temp.c_str());
                  
        }
        |         WRITE Vars 
        {         string temp;
                  temp.append($2.code);
                  size_t pos = temp.find("|", 0);
                  while(pos != string::npos) {
                        temp.replace(pos, 1, ">");
                        pos = temp.find("|", pos);
                  }
                  $$.code = strdup(temp.c_str());
        }
        |         CONTINUE 
        {         $$.code = strdup("continue\n");
        }
        |         RETURN Expression 
        {         string temp;
                  temp.append($2.code);
                  temp.append("ret ");
                  temp.append($2.place);
                  temp.append("\n");
                  $$.code = strdup(temp.c_str()); 
        }
        ;

EStatements:      %empty
        {
                  $$.code = strdup("");
        }
        |         ELSE Statements
        {
                  $$.code = strdup($2.code);
        }
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
        |             Multiplicative_expr SUB Expression
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

Var:		            Ident 
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

    //yylex();
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
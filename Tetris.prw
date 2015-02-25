#include "protheus.ch"

/* ========================================================
Fun��o       U_TETRIS
Autor        J�lio Wittwer
Data         03/11/2014
Vers�o       1.150224
Descri�ao    R�plica do jogo Tetris, feito em AdvPL

Para jogar, utilize as letras :

A ou J = Move esquerda
D ou L = Move Direita
S ou K = Para baixo
W ou I = Rotaciona sentido horario
Barra de Espa�o = Dropa a pe�a

Pendencias

Fazer um High Score

Cores das pe�as

O = Yellow
I = light Blue
L = Orange
Z = Red
S = Green
J = Blue
T = Purple

======================================================== */

STATIC _aPieces := LoadPieces()
STATIC _aColors := { "BLACK2","YELOW2","LIGHTBLUE2","ORANGE2","RED2","GREEN2","BLUE2","PURPLE2" }
STATIC _nGameClock
STATIC _nNextPiece
STATIC _lRunning := .F.  
STATIC _aBMPGrid  := array(20,10)
STATIC _aBMPNext  := array(4,4)
STATIC _aNext := {}

USER Function Tetris()
Local nC
Local nL
Local oDlg
Local aGrid := {}
Local oBackGround
Local oBackNext
Local oTimer
Local oFont
Local oLabel
Local oScore
Local oMsg
Local aDropping := {}
Local nScore := 0

oFont := TFont():New('Courier new',,-16,.T.)

DEFINE DIALOG oDlg TITLE "Tetris" FROM 10,10 TO 450,350 ;
   FONT oFont PIXEL

// Cria um fundo cinza, "esticando" um bitmap
@ 8, 8 BITMAP oBackGround RESOURCE "GRAY2" ;
SIZE 104,204  Of oDlg ADJUST NOBORDER PIXEL

// Desenha na tela um grid de 20x10 com Bitmaps
// para ser utilizado para desenhar a tela do jogo

For nL := 1 to 20
	For nC := 1 to 10
		
		@ nL*10, nC*10 BITMAP oBmp RESOURCE "GRAY2" ;
      SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		_aBMPGrid[nL][nC] := oBmp
		
	Next
Next
               
// Monta um Grid 4x4 para mostrar a proxima pe�a
// ( Grid deslocado 110 pixels para a direita )

@ 8, 118 BITMAP oBackNext RESOURCE "GRAY2" ;
	SIZE 44,44  Of oDlg ADJUST NOBORDER PIXEL

For nL := 1 to 4
	For nC := 1 to 4
		
		@ nL*10, (nC*10)+110 BITMAP oBmp RESOURCE "GRAY2" ;
      SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		_aBMPNext[nL][nC] := oBmp
		
	Next
Next

// Label fixo, t�tulo do Score.
@ 80,120 SAY oLabel PROMPT "[Score]" SIZE 60,10 OF oDlg PIXEL
                                    
// Label para Mostrar score, timers e mensagens do jogo
@ 90,120 SAY oScore PROMPT "        " SIZE 60,120 OF oDlg PIXEL
                                     
// Define um timer, para fazer a pe�a em jogo
// descer uma posi��o a cada um segundo
// ( Nao pode ser menor, o menor tempo � 1 segundo )
oTimer := TTimer():New(1000, ;
	{|| MoveDown(oDlg,oBackGround,aGrid,@aDropping,oTimer,.f.,@nScore) , ;
		 	PaintScore(oScore,nScore)}, oDlg )

// Bot�es com atalho de teclado
// para as teclas usadas no jogo
// colocados fora da area visivel da caixa de dialogo

@ 480,10 BUTTON oDummyBtn PROMPT '&A' ;
  ACTION ( DoAction(oDlg,'A',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore ) );
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&S' ;
  ACTION ( DoAction(oDlg,'S',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&D' ;
  ACTION ( DoAction(oDlg,'D',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL
  
@ 480,20 BUTTON oDummyBtn PROMPT '&W' ;
  ACTION ( DoAction(oDlg,'W',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&J' ;
  ACTION ( DoAction(oDlg,'J',oBackGround,aGrid,@aDropping,oTimer,@nScore,PaintScore(oScore,nScore)) ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&K' ;
  ACTION ( DoAction(oDlg,'K',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&L' ;
  ACTION ( DoAction(oDlg,'L',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&I' ;
  ACTION ( DoAction(oDlg,'I',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL
                                                  
@ 480,20 BUTTON oDummyBtn PROMPT '& ' ; // Espa�o = Dropa
  ACTION ( DoAction(oDlg,' ',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL

@ 480,20 BUTTON oDummyBtn PROMPT '&P' ; // Pause
  ACTION ( DoAction(oDlg,'P',oBackGround,aGrid,@aDropping,oTimer,@nScore),PaintScore(oScore,nScore) ) ;
  SIZE 1, 1 OF oDlg PIXEL

// Na inicializa��o do Dialogo uma partida � iniciada
oDlg:bInit := {|| Start(oDlg,@aDropping,oBackGround,aGrid),;
                  _lRunning := .t.,;
                  oTimer:Activate() }

ACTIVATE DIALOG oDlg CENTER

Return

/* ------------------------------------------------------------
Fun��o Start() Inicia o jogo
------------------------------------------------------------ */

STATIC Function Start(oDlg,aDropping,oBackGround,aGrid)
Local aDraw

// Inicializa o grid de imagens do jogo na mem�ria
// Sorteia a pe�a em jogo
// Define a pe�a em queda e a sua posi��o inicial
// [ Peca, direcao, linha, coluna ]
// e Desenha a pe�a em jogo no Grid
// e Atualiza a interface com o Grid
InitGrid(@aGrid)
nPiece := randomize(1,len(_aPieces)+1)
aDropping := {nPiece,1,1,6}
SetGridPiece(aDropping,aGrid)
PaintGrid(aGrid)

// Sorteia a proxima pe�a e desenha 
// ela no grid reservado para ela 
InitNext()
_nNextPiece := randomize(1,len(_aPieces)+1)
aDraw := {_nNextPiece,1,1,1}
SetGridPiece(aDraw,_aNext)
PaintNext()

// Marca timer do inicio de jogo 
_nGameClock := seconds()

Return

/* ----------------------------------------------------------
Inicializa o Grid na memoria
Em memoria, o Grid possui 14 colunas e 22 linhas
Na tela, s�o mostradas apenas 20 linhas e 10 colunas
As 2 colunas da esquerda e direita, e as duas linhas a mais
sao usadas apenas na memoria, para auxiliar no processo
de valida��o de movimenta��o das pe�as.
---------------------------------------------------------- */

STATIC Function InitGrid(aGrid)
aGrid := array(20,"11000000000011")
aadd(aGrid,"11111111111111")
aadd(aGrid,"11111111111111")
return

STATIC Function InitNext()
_aNext := array(4,"0000")
return

//
// Aplica a pe�a no Grid.
// Retorna .T. se foi possivel aplicar a pe�a na posicao atual
// Caso a pe�a n�o possa ser aplicada devido a haver
// sobreposi��o, a fun��o retorna .F. e o grid n�o � atualizado
//

STATIC Function SetGridPiece(aOnePiece,aGrid)
Local nPiece := aOnePiece[1] // Numero da pe�a
Local nPos   := aOnePiece[2] // Posi��o ( para rotacionar ) 
Local nRow   := aOnePiece[3] // Linha atual no Grid
Local nCol   := aOnePiece[4] // Coluna atual no Grid
Local nL , nC
Local aTecos := {}
Local cTeco, cPeca , cPieceStr

cPieceStr := str(nPiece,1)

For nL := nRow to nRow+3
	cTeco := substr(aGrid[nL],nCol,4)
	cPeca := _aPieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1) == '1'
			If substr(cTeco,nC,1) != '0'
				// Vai haver sobreposi��o,
				// Nao d� para desenhar a pe�a
				Return .F.
			Endif
			cTeco := Stuff(cTeco,nC,1,cPieceStr)
		Endif
	Next
  // Array temporario com a pe�a j� colocada
	aadd(aTecos,cTeco)
Next

// Aplica o array temporario no array do grid
For nL := nRow to nRow+3
	aGrid[nL] := stuff(aGrid[nL],nCol,4,aTecos[nL-nRow+1])
Next

Return .T.


/* ----------------------------------------------------------
Fun��o PaintGrid()
Pinta o Grid do jogo da mem�ria para a Interface

Release 20150222 : Optimiza��o na camada de comunica��o, apenas setar
o nome do resource / bitmap caso o resource seja diferente do atual.
---------------------------------------------------------- */

STATIC Function PaintGrid(aGrid)
Local nL
Local nC

for nL := 1 to 20
	cLine := aGrid[nL]
	For nC := 1 to 10
		nCor := val(substr(cLine,nC+2,1))
		If _aBMPGrid[nL][nC]:cResName != _aColors[nCor+1]
			// Somente manda atualizar o bitmap se houve
			// mudan�a na cor / resource desta posi��o
			_aBMPGrid[nL][nC]:SetBmp(_aColors[nCor+1])
		endif
	Next
Next

Return

// Pinta na interface a pr�xima pe�a 
// a ser usada no jogo 
STATIC Function PaintNext()
Local nL
Local nC

For nL := 1 to 4
	cLine := _aNext[nL]
	For nC := 1 to 4
		nCor := val(substr(cLine,nC,1))
		If _aBMPNext[nL][nC]:cResName != _aColors[nCor+1]
			_aBMPNext[nL][nC]:SetBmp(_aColors[nCor+1])
		endif
	Next
Next

Return

/* -----------------------------------------------------------------
Carga do array de pe�as do jogo 
Array multi-dimensional, contendo para cada 
linha a string que identifica a pe�a, e um ou mais
arrays de 4 strings, onde cada 4 elementos 
representam uma matriz binaria de caracteres 4x4 
para desenhar cada pe�a 

Exemplo - Pe�a "O"      

aLPieces[1][1] C "O"
aLPieces[1][2][1] "0000" 
aLPieces[1][2][2] "0110" 
aLPieces[1][2][3] "0110" 
aLPieces[1][2][4] "0000" 

----------------------------------------------------------------- */

STATIC Function LoadPieces()
Local aLPieces := {}

// Pe�a "O" , uma posi��o
aadd(aLPieces,{'O',	{	'0000','0110','0110','0000'}})

// Pe�a "I" , em p� e deitada
aadd(aLPieces,{'I',	{	'0000','1111','0000','0000'},;
                        {	'0010','0010','0010','0010'}})

// Pe�a "S", em p� e deitada
aadd(aLPieces,{'S',	{	'0000','0011','0110','0000'},;
                        {	'0010','0011','0001','0000'}})

// Pe�a "Z", em p� e deitada
aadd(aLPieces,{'Z',	{	'0000','0110','0011','0000'},;
                        {	'0001','0011','0010','0000'}})

// Pe�a "L" , nas 4 posi��es possiveis
aadd(aLPieces,{'L',	{	'0000','0111','0100','0000'},;
                        {	'0010','0010','0011','0000'},;
                        {	'0001','0111','0000','0000'},;
                        {	'0110','0010','0010','0000'}})

// Pe�a "J" , nas 4 posi��es possiveis
aadd(aLPieces,{'J',	{	'0000','0111','0001','0000'},;
                        {	'0011','0010','0010','0000'},;
                        {	'0100','0111','0000','0000'},;
                        {	'0010','0010','0110','0000'}})

// Pe�a "T" , nas 4 posi��es possiveis
aadd(aLPieces,{'T',	{	'0000','0111','0010','0000'},;
                        {	'0010','0011','0010','0000'},;
                        {	'0010','0111','0000','0000'},;
                        {	'0010','0110','0010','0000'}})


Return aLPieces


/* ----------------------------------------------------------
Fun��o MoveDown()

Movimenta a pe�a em jogo uma posi��o para baixo.
Caso a pe�a tenha batido em algum obst�culo no movimento
para baixo, a mesma � fica e incorporada ao grid, e uma nova
pe�a � colocada em jogo. Caso n�o seja possivel colocar uma
nova pe�a, a pilha de pe�as bateu na tampa -- Game Over

---------------------------------------------------------- */

STATIC Function MoveDown(oDlg,oBackGround,aGrid,aDropping,oTimer,lDrop,nScore)
Local aOldPiece

If !_lRunning
   Return
Endif

// Clona a pe�a em queda na posi��o atual
aOldPiece := aClone(aDropping)

If lDrop
	
	// Dropa a pe�a at� bater embaixo
	// O Drop incrementa o score em 1 ponto 
	// para cada linha percorrida. Quando maior a quantidade
	// de linhas vazias, maior o score acumulado com o Drop
	
	// Guarda a pe�a na posi��o atual
	aOldPiece := aClone(aDropping)
	
	// Remove a pe�a do Grid atual
	DelPiece(aDropping,aGrid)
	
	// Desce uma linha pra baixo
	aDropping[3]++
	
	While SetGridPiece(aDropping,aGrid)
		
		// Encaixou, remove e tenta de novo
		DelPiece(aDropping,aGrid)
		
		// Guarda a pe�a na posi��o atual
		aOldPiece := aClone(aDropping)
		
		// Desce a pe�a mais uma linha pra baixo
		aDropping[3]++

		// Incrementa o Score
		nScore++
				
	Enddo
	
	// Nao deu mais pra pintar, "bateu"
	// Volta a pe�a anterior, pinta o grid e retorna
	// isto permite ainda movimentos laterais
	// caso tenha espa�o.
	
	aDropping := aClone(aOldPiece)
	SetGridPiece(aDropping,aGrid)
	PaintGrid(aGrid)
	
Else
	
	// Move a pe�a apenas uma linha pra baixo
	
	// Primeiro remove a pe�a do Grid atual
	DelPiece(aDropping,aGrid)
	
	// Agora move a pe�a apenas uma linha pra baixo
	aDropping[3]++
	
	// Recoloca a pe�a no Grid
	If SetGridPiece(aDropping,aGrid)
		
		// Se deu pra encaixar, beleza
		// pinta o novo grid e retorna
		PaintGrid(aGrid)
		Return
		
	Endif
	
	// Opa ... Esbarrou em alguma coisa
	// Volta a pe�a pro lugar anterior
	// e recoloca a pe�a no Grid
	aDropping :=  aClone(aOldPiece)
	SetGridPiece(aDropping,aGrid)

	// Incrementa o score em 4 pontos 
	// Nao importa a pe�a ou como ela foi encaixada
	nScore += 4

	// Agora verifica se da pra limpar alguma linha
	CheckLines(@aGrid,@nScore)
	
	// Pega a proxima pe�a
	nPiece := _nNextPiece
	aDropping := {nPiece,1,1,6} // Peca, direcao, linha, coluna

	If !SetGridPiece(aDropping,aGrid)
		
		// Acabou, a pe�a nova nao entra (cabe) no Grid
		// Desativa o Timer e mostra "game over"
		// e fecha o programa

		// e volta os ultimos 4 pontos ...		
		nScore -= 4
		_lRunning := .F.
		_nGameClock := round(seconds()-_nGameClock,0)
		oTimer:Deactivate()                             
		
	Endif
	
	// Se a peca tem onde entrar, beleza
	// -- Repinta o Grid -- 
	PaintGrid(aGrid)

	// E Sorteia a proxima pe�a
	InitNext()
	_nNextPiece := randomize(1,len(_aPieces)+1)
	aDraw := {_nNextPiece,1,1,1}
	SetGridPiece(aDraw,_aNext)
	PaintNext()
	
Endif

Return

/* ----------------------------------------------------------
Recebe uma a��o da interface, atrav�s de uma das letras
de movimenta��o de pe�as, e realiza a movimenta��o caso
haja espa�o para tal.
---------------------------------------------------------- */
STATIC Function DoAction(oDlg,cAct,oBackGround,aGrid,aDropping,oTimer,nScore)
Local aOldPiece

// conout("Action  = ["+cAct+"]")

If !_lRunning
   Return
Endif

// Clona a pe�a em queda
aOldPiece := aClone(aDropping)

if cAct $ 'AJ'

	// Movimento para a Esquerda (uma coluna a menos)
	// Remove a pe�a do grid
	DelPiece(aDropping,aGrid)
	aDropping[4]--
	If !SetGridPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		aDropping :=  aClone(aOldPiece)
		SetGridPiece(aDropping,aGrid)
	Endif
	// Repinta o Grid
	PaintGrid(aGrid)
	
Elseif cAct $ 'DL'

	// Movimento para a Direita ( uma coluna a mais )
	// Remove a pe�a do grid
	DelPiece(aDropping,aGrid)
	aDropping[4]++'
	If !SetGridPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		aDropping :=  aClone(aOldPiece)
		SetGridPiece(aDropping,aGrid)
	Endif
	// Repinta o Grid
	PaintGrid(aGrid)
	
Elseif cAct $ 'WI'
	
	// Movimento para cima  ( Rotaciona sentido horario )
	
	// Remove a pe�a do Grid
	DelPiece(aDropping,aGrid)
	
	// Rotaciona
	aDropping[2]--
	If aDropping[2] < 1
		aDropping[2] := len(_aPieces[aDropping[1]])-1
	Endif
	
	If !SetGridPiece(aDropping,aGrid)
		// Se nao consegue colocar a pe�a no Grid
		// Nao � possivel rotacionar. Pinta a pe�a de volta
		aDropping :=  aClone(aOldPiece)
		SetGridPiece(aDropping,aGrid)
	Endif
	
	// E Repinta o Grid
	PaintGrid(aGrid)
	
ElseIF cAct $ 'SK'
	
	// Desce a pe�a para baixo uma linha
	MoveDown(oDlg,oBackGround,aGrid,@aDropping,oTimer,.F.,@nScore)
	
ElseIF cAct == ' '
	
	// Dropa a pe�a - empurra para baixo at� a �ltima linha
	// antes de baer a pe�a no fundo do Grid
	MoveDown(oDlg,oBackGround,aGrid,@aDropping,oTimer,.T.,@nScore)
	
ElseIF cAct == 'P'
	
	// Pausa
	MsgInfo("PAUSE - Clique no bot�o abaixo para continuar.")

Endif

Return .T.

/* -----------------------------------------------------------------------
Remove uma pe�a do Grid atual
----------------------------------------------------------------------- */
STATIC Function DelPiece(aDropping,aGrid)

Local nPiece := aDropping[1]
Local nPos   := aDropping[2]
Local nRow   := aDropping[3]
Local nCol   := aDropping[4]
Local nL, nC
Local cTeco, cPeca

// Como a matriz da pe�a � 4x4, trabalha em linhas e colunas
// Separa do grid atual apenas a �rea que a pe�a est� ocupando
// e desliga os pontos preenchidos da pe�a no Grid.
For nL := nRow to nRow+3
	cTeco := substr(aGrid[nL],nCol,4)
	cPeca := _aPieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1)=='1'
			cTeco := Stuff(cTeco,nC,1,'0')
		Endif
	Next
	aGrid[nL] := stuff(aGrid[nL],nCol,4,cTeco)
Next

Return

/* -----------------------------------------------------------------------
Verifica se alguma linha esta completa e pode ser eliminada
----------------------------------------------------------------------- */
STATIC Function CheckLines(aGrid , nScore )
Local nErased := 0 

// Sempre varre de baixo para cima

For nL := 20 to 2 step -1
	
	// Pega uma linha, e remove os espa�os vazios
	cTeco := substr(aGrid[nL],3)
	cNewTeco := strtran(cTeco,'0','')
	
	
	If len(cNewTeco) == len(cTeco)
		// Se o tamanho da linha se manteve, n�o houve
		// nenhuma redu��o, logo, n�o h� espa�os vazios
		// Elimina esta linha e acrescenta uma nova linha
		// em branco no topo do Grid
		adel(aGrid,nL)
		ains(aGrid,1)
		aGrid[1] := "11000000000011"
		nL++
		nErased++
		If nErased == 4 
		   nScore += 100
		ElseIf nErased == 3 
		   nScore += 50
		ElseIf nErased == 2
		   nScore += 25
		ElseIf nErased == 1
		   nScore += 10
	  Endif
	Endif
	
Next

Return


/* ------------------------------------------------------
Seta o score do jogo na tela
Caso o jogo tenha terminado, acrescenta 
a mensagem  de "GAME OVER"
------------------------------------------------------*/
STATIC Function PaintScore(oScore,nScore)
Local nGameTime

If _lRunning

	// JOgo em andamento, apenas atualiza score e timer
	oScore:SetText(strzero(nScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+cValToChar(round(seconds()-_nGameClock,0))+' s.')

Else  

	// Terminou, acresenta a mensagem de "GAME OVER"
	oScore:SetText(strzero(nScore,7)+CRLF+CRLF+;
		'[Time]'+CRLF+cValToChar(_nGameClock)+' s.'+CRLF+CRLF+;
		"********"+CRLF+;
		"* GAME *"+CRLF+;
		"********"+CRLF+;
		"* OVER *"+CRLF+;
		"********")

Endif

Return

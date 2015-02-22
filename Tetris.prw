#include "protheus.ch"

/* ========================================================
Fun��o       U_TETRIS
Autor        J�lio Wittwer
Data         03/11/2014
Vers�o       1.141103
Descri�ao    R�plica do jogo Tetris, feito em AdvPL

Para jogar, utilize as letras:

A = Move esquerda
D = Move Direita
S = PAra baixo
W = Rotaciona sentido horario

Pendencias

Calcular e mostrar pontua��o / score
Calcular e mostrar tempo de jogo
Mostrar a proxima pe�a que vai cair
Fazer um High Score

======================================================== */

STATIC aPieces := LoadPieces()
STATIC aColors := { "BLACK","BLUE","RED","GREEN","ORANGE","PURPLE","YELOW","LIGHTBLUE" }


USER Function Tetris()
Local nC
Local nL
Local oDlg
Local aBMPGrid := array(20,10)
Local aGrid := {}
Local oBackGround
Local cAct := ' '
Local oTimer
Local aDropping := {}
Local lRunning := .F.

// Carrega os arrays com as defini��es das pe�as
LoadPieces()

DEFINE DIALOG oDlg TITLE "Tetris" FROM 10,10 TO 600,400 PIXEL

// Cria um fundo cinza, "esticando" um bitmap
@ 8, 8 BITMAP oBackGround RESOURCE "GRAY" ;
   SIZE 104,204  Of oDlg ADJUST NOBORDER PIXEL

// Desenha na tela um grid de 20x10 com Bitmaps
// para ser utilizado para desenhar a tela do jogo

For nL := 1 to 20
	For nC := 1 to 10
		
		@ nL*10, nC*10 BITMAP oBmp RESOURCE "GRAY" ;
		   SIZE 10,10  Of oDlg ADJUST NOBORDER PIXEL
		
		aBMPGrid[nL][nC] := oBmp
		
	Next
Next

// Define um timer, para fazer a pe�a em jogo 
// descer uma posi��o a cada um segundo 
// ( Nao pode ser menor, o menor tempo � 1 segundo ) 
oTimer := TTimer():New(1000, ;
   {|| GoDown(oDlg,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer,.f.),oAct:Setfocus() }, oDlg )

// Bot�o para iniciar o jogo
@ 230,10 BUTTON oDummyBtn PROMPT 'Start' ;
  ACTION (Start(oDlg,@aDropping,oBackGround,aBMPGrid,aGrid),lRunning := .t.,oTimer:Activate(),oAct:Setfocus()) ;
  SIZE 80, 010 OF oDlg PIXEL

// Get de um caractere com 1 Byte de tamanho para obter 
// qual e a a��o a ser realizada com a pe�a em jogo
@ 230,90 GET oAct VAR cAct PICTURE "!" ;
  MESSAGE "Action" SIZE 0,0 ;
  WHEN lRunning ;
  VALID ( DoAction(oDlg,cAct,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer),oAct:Setfocus(),.t. ) OF oDlg PIXEL

ACTIVATE DIALOG oDlg CENTER

Return

/*
Fun��o Start()
Inicia o jogo
*/

STATIC Function Start(oDlg,aDropping,oBackGround,aBmpGrid,aGrid)

// Sorteia a pe�a em jogo
nPiece := randomize(1,len(aPieces)+1)

// Inicializa o grid de imagens do jogo na mem�ria
InitGrid(@aGrid)

// Define a pe�a em queda e a sua posi��o inicial 
// Peca, direcao, linha, coluna
aDropping := {nPiece,1,1,6} 

// Desenha a pe�a em jogo no Grid
PutPiece(aDropping,aGrid)        

// Atualiza a interface com o Grid
PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)

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

//
// Aplica a pe�a no Grid.
// Retorna .T. se foi possivel aplicar a pe�a na posicao atual
// Caso a pe�a n�o possa ser aplicada devido a haver 
// sobreposi��o, a fun��o retorna .F. e o grid n�o � atualizado
//

STATIC Function PutPiece(aOnePiece,aGrid)
Local nPiece := aOnePiece[1]
Local nPos := aOnePiece[2]
Local nRow := aOnePiece[3]
Local nCol := aOnePiece[4]
Local nL
Local nOver := 0
Local aTecos := {}
cPieceStr := str(nPiece,1)
For nL := nRow to nRow+3
	cTeco := substr(aGrid[nL],nCol,4)
	cPeca := aPieces[nPiece][1+nPos][nL-nRow+1]
	For nC := 1 to 4
		If Substr(cPeca,nC,1)=='1'
			If substr(cTeco,nC,1)!='0'
				nOver++
				EXIT
			Else
				cTeco := Stuff(cTeco,nC,1,cPieceStr)
			Endif
		Endif
	Next
	aadd(aTecos,cTeco)
	If nOver <> 0
		EXIT
	Endif
Next

If nOver == 0
	For nL := nRow to nRow+3
		aGrid[nL] := stuff(aGrid[nL],nCol,4,aTecos[nL-nRow+1])
	Next
Endif

Return ( nOver == 0 )


/* ----------------------------------------------------------
Fun��o PaintGrid()
Pinta o Grid do jogo da mem�ria para a Interface
---------------------------------------------------------- */


STATIC Function PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
Local nL
Local nC

oBackGround:SetBmp("Gray")

for nL := 1 to 20
	cLine := aGrid[nL]
	For nC := 1 to 10
		nCor := val(substr(cLine,nC+2,1))
		aBmpGrid[nL][nC]:SetBmp(aColors[nCor+1])
		// aBmpGrid[nL][nC]:Refresh()
	Next
Next

Return


STATIC Function LoadPieces()
Local aLocalPieces := {}
                        
// Pe�a "O" , uma posi��o 
aadd(aLocalPieces,{'O',	{	'0000','0110','0110','0000'}})

// Pe�a "I" , em p� e deitada
aadd(aLocalPieces,{'I',	{	'0000','1111','0000','0000'},;
                        {	'0010','0010','0010','0010'}})

// Pe�a "S", em p� e deitada
aadd(aLocalPieces,{'S',	{	'0000','0011','0110','0000'},;
                        {	'0010','0011','0001','0000'}})

// Pe�a "Z", em p� e deitada
aadd(aLocalPieces,{'Z',	{	'0000','0110','0011','0000'},;
                        {	'0001','0011','0010','0000'}})

// Pe�a "L" , nas 4 posi��es possiveis
aadd(aLocalPieces,{'L',	{	'0000','0111','0100','0000'},;
                        {	'0010','0010','0011','0000'},;
                        {	'0001','0111','0000','0000'},;
                        {	'0110','0010','0010','0000'}})

// Pe�a "J" , nas 4 posi��es possiveis
aadd(aLocalPieces,{'J',	{	'0000','0111','0001','0000'},;
                        {	'0011','0010','0010','0000'},;
                        {	'0100','0111','0000','0000'},;
                        {	'0010','0010','0110','0000'}})

// Pe�a "T" , nas 4 posi��es possiveis
aadd(aLocalPieces,{'T',	{	'0000','0111','0010','0000'},;
                        {	'0010','0011','0010','0000'},;
                        {	'0010','0111','0000','0000'},;
                        {	'0010','0110','0010','0000'}})


Return aLocalPieces


/* ----------------------------------------------------------
Fun��o GoDown()

Movimenta a pe�a em jogo uma posi��o para baixo. 
Caso a pe�a tenha batido em algum obst�culo no movimento 
para baixo, a mesma � fica e incorporada ao grid, e uma nova 
pe�a � colocada em jogo. Caso n�o seja possivel colocar uma
nova pe�a, a pilha de pe�as bateu na tampa -- Game Over

---------------------------------------------------------- */

STATIC Function GoDown(oDlg,oBackGround,aBMPGrid,aGrid,aDropping,lRunning,oTimer,lDrop)
Local aOldPiece

// Clona a pe�a em queda na posi��o atual 
aOldPiece := aClone(aDropping)

If lDrop
	
	// Dropa a peca ate bater embaixo
	While .T.
		
		// Remove a pe�a do Grid atual
		DelPiece(aDropping,aGrid)
		
		// uma linha pra baixo
		aDropping[3]++
		
		If PutPiece(aDropping,aGrid)
			// Encaixou, remove e tenta de novo
			DelPiece(aDropping,aGrid)
			aOldPiece := aClone(aDropping)
			LOOP
		Endif
		
		// Nao deu mais pra pintar, ^bateu^
		// Volta a pe�a anterior
		// pinta o grid e retorna
		
		aDropping := aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
		PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
		Return
		
	Enddo
	
Endif

// Vamos mover apenas uma linha pra baixo

// Remove a pe�a do Grid atual
DelPiece(aDropping,aGrid)

// Move a pe�a apenas uma linha pra baixo
aDropping[3]++

// Recoloca a pe�a no Grid
If PutPiece(aDropping,aGrid)
	
	// Se deu pra encaixar, beleza
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	Return
	
Endif

// opa ... bateu no final ...
// Volta a pe�a pro lugar anterior e chumba ...
aDropping :=  aClone(aOldPiece)
PutPiece(aDropping,aGrid)

// Beleza, agora verifica se da pra limpar alguma linha
CheckLines(@aGrid)

// agora cria uma pe�a nova
nPiece := randomize(1,len(aPieces)+1)
aDropping := {nPiece,1,1,6} // Peca, direcao, linha, coluna

If PutPiece(aDropping,aGrid)
	// se a peca tem onde entrar, beleza
	// Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
Else
  // Acabou, a pe�a nova nao entra (cabe) no Grid
  // Desativa o Timer e mostra "game over"
	lRunning := .f.
	oTimer:Deactivate()
	MsgStop("*** GAME OVER ***")
Endif

return

/* ----------------------------------------------------------
Recebe uma a��o da interface, atrav�s de uma das letras 
de movimenta��o de pe�as, e realiza a movimenta��o caso 
haja espa�o para tal. 
---------------------------------------------------------- */
STATIC Function DoAction(oDlg,cAct,oBackGround,aBMPGrid,aGrid,aDropping,lRunning,oTimer)
Local aOldPiece

// conout("Action  = ["+cAct+"]")

// Clona a pe�a em queda
aOldPiece := aClone(aDropping)

if cAct $ 'AJ'
	// Movimento para a Esquerda
	// uma coluna a menos
	// Remove a pe�a do grid
	DelPiece(aDropping,aGrid)
	aDropping[4]--
	If !PutPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		aDropping :=  aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
	Endif
	// Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	
Elseif cAct $ 'DL'
	// Movimento para a Direita
	// uma coluna a mais
	// Remove a pe�a do grid
	DelPiece(aDropping,aGrid)
	aDropping[4]++'
	If !PutPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		aDropping :=  aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
	Endif
	// Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	
Elseif cAct $ 'WI'
	
  // ( Movimento para cima ) 
	// Rotaciona sentido horario
	
	DelPiece(aDropping,aGrid)
	
	aDropping[2]--
	If aDropping[2] < 1
		aDropping[2] := len(aPieces[aDropping[1]])-1
	Endif
	
	If !PutPiece(aDropping,aGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		aDropping :=  aClone(aOldPiece)
		PutPiece(aDropping,aGrid)
	Endif
	
	// E Repinta o Grid
	PaintGrid(oDlg,oBackGround,aGrid,aBmpGrid)
	
ElseIF cAct $ 'SK'
	
	// Empurra pra baixo uma linha
	GoDown(oDlg,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer,.f.)
	
ElseIF cAct == ' '
	
	// Dropa a peca - empurra para baixo at� a �ltima linha
	// antes de baer a pe�a no fundo do Grid
	GoDown(oDlg,oBackGround,aBMPGrid,aGrid,@aDropping,@lRunning,oTimer,.t.)
	
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

For nL := nRow to nRow+3
  cTeco := substr(aGrid[nL],nCol,4)
  cPeca := aPieces[nPiece][1+nPos][nL-nRow+1]
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
STATIC Function CheckLines(aGrid)
For nL := 20 to 2 step -1
	cTeco := substr(aGrid[nL],3)
	cNewTeco := strtran(cTeco,'0','')
	If len(cNewTeco) == len(cTeco)
		// Linha cheia, elimina a linha e acrescenta 
		// Uma nova linha em branco no topo do Grid
	  adel(aGrid,nL)
    ains(aGrid,1)
    aGrid[1] := "11000000000011"
    nL++
	Endif
Next
Return

MODULE MODELS_MOD
!===============================================================================
  CONTAINS
!===============================================================================
  SUBROUTINE MODELS(M,VARENT, VARSAI, PARAM, GUESS)
    INTEGER :: M
    REAL(8), INTENT(IN) :: VARENT(:)
    REAL(8), INTENT(OUT) :: VARSAI(:)
    REAL(8), INTENT(IN) :: GUESS(:)
    REAL(8) :: PARAM(:)
    SELECT CASE(M)
    CASE(1)
      CALL MODEL_A(VARENT, VARSAI, PARAM, GUESS)
    ENDSELECT
  ENDSUBROUTINE
!===============================================================================
  SUBROUTINE MODEL_A(VARENT, VARSAI, PARAM, GUESS)
    REAL(8), INTENT(IN) :: VARENT(:)
    REAL(8), INTENT(OUT) :: VARSAI(:)
    REAL(8), INTENT(IN) :: GUESS(:)
    REAL(8) :: PARAM(:)
    !MODELO
    INTEGER :: I
    !DECLARAÇÃO DE VARIÁVEIS PARA A DASSL
    INTEGER NEQ, INFO(15), IDID, LRW, LIW, IWORK(22), IPAR(1)
    DOUBLE PRECISION T, Y(2), YPRIME(2), TOUT, RTOL, ATOL, RWORK(62), RPAR(3)
    !DECLARAÇÃO DE VARIÁVEIS DO PROBLEMA
    DOUBLE PRECISION H, FO, ST, KV, FI
    DOUBLE PRECISION HPRIME,FOPRIME
    DOUBLE PRECISION DT, TEND(10)
    !VARIÁVEIS AUXILIARES DO PROGRAMA
    !FORMULAÇÃO DO PROBLEMA
    
    KV = PARAM(1)
    
    !ATRIBUINDO VALORES ÀS CONSTANTES
    ST=1.D0        !ÁREA TRANSVERSAL DO TANQUE
!    KV=1.D0        !CONSTANTE DA VÁLVULA
    
    !DEFININDO A CONDIÇÃO DE CONTORNO
    FI=1.D0        !VAZÃO DE ENTRADA
    
    !DEFININDO CONDIÇÕES INICIAIS DO PROCESSO
    H =0.D0        !ALTURA DE LÍQUIDO NO TANQUE
    FO=0.D0        !VAZÃO DE SAÍDA
    
    !DEFININDO ESTIMATIVAS INICIAIS PARA O MÉTODO NUMÉRICO
    HPRIME=FI/ST   !DERIVADA DE H EM RELAÇÃO AO TEMPO
    FOPRIME=KV*FI/ST   !DERIVADA DE F0 EM RELAÇÃO AO TEMPO
    
    !INICIANDO OS PARÂMETROS DA DASSL
    T=0.D0         !TEMPO ATUAL (TEMPO INICIAL NESSE CASO)
    DT=1.D-1       !TAMANHO DO PASSO NO TEMPO
    TEND=VARENT(:)        !DURAÇÃO DA SIMULAÇÃO DO ENCHIMENTO DE TANQUE
    Y(1)=H         !PASSAGEM DA CONDIÇAO INICIAL PARA UM VETOR LEGIVEL PELA DASSL
    Y(2)=FO        !PASSAGEM DA CONDIÇAO INICIAL PARA UM VETOR LEGIVEL PELA DASSL
    YPRIME(1)=HPRIME     !PASSAGEM DA CONDIÇAO INICIAL PARA UM VETOR LEGIVEL PELA DASSL   
    YPRIME(2)=FOPRIME    !PASSAGEM DA CONDIÇAO INICIAL PARA UM VETOR LEGIVEL PELA DASSL
    TOUT=T+DT      !TEMPO FINAL DDO PRIMEIRO PASSO DA INTEGRAÇÃO NO TEMPO
    INFO=0         !VETOR CONTENDO OPÇOES DA DASSL. DEFAULT=0
    RTOL=1.D-6     !TOLERÂNCIA RELATIVA
    ATOL=1.D-8     !TOLERÂNCIA ABSOLUTA
    NEQ=2          !NÚMERO DE EQUAÇÕES
    LIW=22         !O CÁLCULO DESSE VALOR É ENSINADO NO CÓDIGO DA DASSL
    LRW=62         !O CÁLCULO DESSE VALOR É ENSINADO NO CÓDIGO DA DASSL

    !PASSAGEM DE VARIÁVEIS PARA A SUBROTINA RES()
    RPAR(1)=ST
    RPAR(2)=KV
    RPAR(3)=FI
    
    !ABRINDO ARQUIVOS PARA GRAVAÇÃO DE DADOS
!    WRITE(*,*)         'TEMPO   H     FO   dHdt     dFOdt'
!    WRITE(*,"(5(F6.3, 1x))") T,Y(:)
    
    !ROTINA DE CHAMADA DA DASSL PARA INTEGRAÇÃO DO SISTEMA DE DAEs, EM PASSOS DE TEMPO DT, ATÉ O TEMPO FINAL TEND
    DO I=1,10
      DO WHILE (T < TEND(I))
        CALL DDASSL (RES, NEQ, T, Y, YPRIME, TOUT, INFO, RTOL, ATOL, IDID, RWORK, LRW, IWORK, LIW, RPAR, IPAR, JAC) !INTEGRA O O SISTEMA
        TOUT=T+DT
!        WRITE(*,"(5(F6.3, 1x))") T,Y(:), YPRIME(:)
      enddo
      VARSAI(I) = Y(1)
    ENDDO
  

  ENDSUBROUTINE
!===============================================================================
  SUBROUTINE RES(T,Y,YPRIME,DELTA,IRES,RPAR,IPAR)
    !FUNÇÃO RESIDUO PARA O SOLVER ALGEBRICO DIFERENCIAL DASSL
    DOUBLE PRECISION T, Y(*), YPRIME(*), DELTA(*), RPAR(*)
    INTEGER IRES,IPAR(*)
    
    DOUBLE PRECISION H, FO, ST, KV, FI
    DOUBLE PRECISION HPRIME,FOPRIME
    !RELITERANDO AS VARIÁVEIS DA DASSL 
    !N.A. (APENAS PARA FINS DIDÁTICOS. É RECOMENDÁVEL TRABALHAR DIRETAMENTE COM Y,YPRIME, IPAR E RPAR)
    H=Y(1)
    HPRIME=YPRIME(1)
    FO=Y(2)
!    FOPRIME=YPRIME(2) !FOPRIME NÃO SERÁ UTILIZADO NAS EQUAÇÕES, ENTÃO PODE SER IGNORADO
    ST=RPAR(1)
    KV=RPAR(2)
    FI=RPAR(3) 
    !------------------------------------------
    !FORMULAÇÃO DO PROBLEMA
    !AQUI DEVEM SER INSERIDAS AS EQUAÇÕES DIFERENCIAIS E ALGÉBRICAS
    !ELAS DEVEM ESTAR NA FORMA DELTA(I)=F(Y,Y',t)
    !e.g. PARA UMA VARIÁVEL 'F' GENÉRICA TEMOS A EQUAÇÃO: dF/dt=F -> DELTA=dF/dt-F
    !     PARA A DASSL F=Y, LOGO, A EQUAÇÃO DEVE SER ESCRITA EM FORTRAN COMO: DELTA(I)=YPRIME(I)-Y(I) PARA I=1,...,NEQ
    DELTA(1)=-ST*HPRIME+FI-FO !EQUAÇÃO DIFERENCIAL
    DELTA(2)=-FO+KV*H  !EQUAÇÃO ALGÉBRICA
    
  ENDSUBROUTINE
!===============================================================================
  SUBROUTINE JAC(T,Y,YPRIME,PD,CJ,RPAR,IPAR)
    !FUNÇÃO JACOBIANA PARA O SOLVER ALGEBRICO DIFERENCIAL DASSL
!O FORNECIMENTO DE UMA SUBROTINA PARA CALCULO DA JACOBIANA E NECESSARIO
!POIS A DASSL REQUER LINKAR ESSA ROTINA AO EXECUTÁVEL INDEPENDENTEMENTE DA INTENÇÃO DE USO
!QUE É DEFINIDA EM UMA DAS VARIÁVEIS INFO DELA
  real(8) T, Y(*), PD(*), CJ, YPRIME(*), RPAR(*)
  INTEGER IPAR(*)
!NO CASO DE USAR INFO INDICANDO QUE ELA NÃO VAI SER CHAMADA
!ELA DEVE SER DECLARADA AQUI MAS PODE FICAR SEM IMPLEMENTAÇÃO
  END SUBROUTINE
!===============================================================================
ENDMODULE

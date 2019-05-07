//+------------------------------------------------------------------------------+
//|                                                       Falcon EA Template v2.0|
//|                                                     Copyright 2015,Lucas Liew| 
//|                                               lucas@blackalgotechnologies.com| 
//|                                                    Stat_Euclidean_Metric.mq4 |
//|                                                                  StatBars TO |
//|                                                  http://ridecrufter.narod.ru |
//|                           Best uses with explanations provided in this course|
//| https://www.udemy.com/self-learning-trading-robot/?couponCode=SELF-LEARN-BOT |
//+------------------------------------------------------------------------------+
#include <01_GetHistoryOrder.mqh>
#include <02_OrderProfitToCSV.mqh>
#include <03_ReadCommandFromCSV.mqh>
#include <08_TerminalNumber.mqh>
#include <096_ReadMarketTypeFromCSV.mqh>
#include <10_isNewBar.mqh>
#include <16_LogMarketType.mqh>
#include <17_CheckIfMarketTypePolicyIsOn.mqh>

#property copyright "Copyright 2018, Vladimir Zhbanko"
#property link      "https://vladdsm.github.io/myblog_attempt/"
#property version "1.04"  
#property strict

#define v_dim_x 6 //number of vectors used for recognition...
#define Num_neighbour 10 //number of nearest neighbours to forecast whether new values belongs to 0 or 1
/* 
==================================================================
VERY VERY IMPORTANT: USE STRATEGY TESTER TO PERFORM ROBOT TRAINING
==================================================================
1. Set parameter Base = True
2. Select time period and start trading simulation
3. Switch parameter Base = False, test trading again
4. Move *.dat files from tester folder to Files folder of the sandbox and launch the robot

Release Notes: 
- System is based on the Falcon Template that is now containing custom functions
- System is working using kNN algorithm and output the probabilities to win trades adapted from Stat_Euclidean_Metric.mq4
- System uses history experience to enter the trade
- History experience is created in TESTER
- In order to trade files.dat must be manually transferred to the File sandbox
- Made some corrections acc to: https://www.mql5.com/ru/code/8645
- Trading system is only working on new bar entry
- Rearranged Headers
- 90 minor warnings
v1.01 Release Notes: 
- critical fix: adding buy probability formula as it was missed
- set variable close_orders = true by default as this teach the system to be more robust, much less trades are generated in live trading
- critical fix: invese position open added variable to trading conditions
v1.04 Release Notes: 
- added full features of Decision Support System developed so far
- see Falcon_F2
- less minor warnings
- to be used with Market Type Recognition
*/

//+------------------------------------------------------------------+
//| Setup                                               
//+------------------------------------------------------------------+
extern string  Header1="----------EA General Settings-----------";
extern int     MagicNumber           = 8132100;
extern int     TerminalType          = 1;         //0 mean slave, 1 mean master
extern bool    R_Management          = true;      //R_Management to set true for trading, false for testing
extern int     Slippage              = 3;         //Slippage In Pips
extern bool    IsECNbroker           = false;     // Is your broker an ECN
extern bool    OnJournaling          = false;      // Add EA updates in the Journal Tab
extern bool    EnableDashboard       = false; // Turn on Dashboard

extern string  Header2="----------Trading Rules Variables-----------";
extern bool    Base                    =false;
extern double  buy_threshold           =0.7;
extern double  sell_threshold          =0.7;
extern bool    inverse_position_open   =false;
extern double  invers_buy_threshold    =0.3;
extern double  invers_sell_threshold   =0.3;
extern int     fast                    =12;
extern int     slow                    =26;
extern int     KeltnerPeriod           =20;
extern int     KeltnerMulti            =1;
extern bool    close_orders            =false; 
extern bool    use_market_type         =false;

extern string  Header3="----------Position Sizing Settings-----------";
extern string  Lot_explanation         ="If IsSizingOn = true, Lots variable will be ignored";
extern double  Lots                    =0.01;
extern bool    IsSizingOn              =False;
extern double  Risk                    =1; // Risk per trade (in percentage)
extern int     MaxPositionsAllowed     =1;

extern string  Header4="----------TP & SL Settings-----------";

extern bool    UseFixedStopLoss        =True; // If this is false and IsSizingOn = True, sizing algo will not be able to calculate correct lot size. 
extern double  FixedStopLoss           =0; // Hard Stop in Pips. Will be overridden if vol-based SL is true 
extern bool    IsVolatilityStopOn      =True;
extern double  VolBasedSLMultiplier    =5; // Stop Loss Amount in units of Volatility

extern bool    UseFixedTakeProfit      =True;
extern double  FixedTakeProfit         =0; // Hard Take Profit in Pips. Will be overridden if vol-based TP is true 
extern bool    IsVolatilityTakeProfitOn=True;
extern double  VolBasedTPMultiplier    =5; // Take Profit Amount in units of Volatility

extern string  Header5="----------Hidden TP & SL Settings-----------";

extern bool    UseHiddenStopLoss       =False;
extern double  FixedStopLoss_Hidden    =0; // In Pips. Will be overridden if hidden vol-based SL is true 
extern bool    IsVolatilityStopLossOn_Hidden=False;
extern double  VolBasedSLMultiplier_Hidden=0; // Stop Loss Amount in units of Volatility

extern bool    UseHiddenTakeProfit     =False;
extern double  FixedTakeProfit_Hidden  =0; // In Pips. Will be overridden if hidden vol-based TP is true 
extern bool    IsVolatilityTakeProfitOn_Hidden=False;
extern double  VolBasedTPMultiplier_Hidden=0; // Take Profit Amount in units of Volatility

extern string  Header6="----------Breakeven Stops Settings-----------";
extern bool    UseBreakevenStops       =False;
extern double  BreakevenBuffer         =0; // BreakevenBuffer In pips

extern string  Header7="----------Hidden Breakeven Stops Settings-----------";
extern bool    UseHiddenBreakevenStops =False;
extern double  BreakevenBuffer_Hidden  =0; // BreakevenBuffer_Hidden In pips

extern string  Header8="----------Trailing Stops Settings-----------";
extern bool    UseTrailingStops=False;
extern double  TrailingStopDistance    =50; // TrailingStopDistance In pips
extern double  TrailingStopBuffer      =0;   // TrailingStopBuffer In pips

extern string  Header9="----------Hidden Trailing Stops Settings-----------";
extern bool    UseHiddenTrailingStops=False;
extern double  TrailingStopDistance_Hidden=30; //TrailingStopDistance_Hidden In pips
extern double  TrailingStopBuffer_Hidden=0; //TrailingStopBuffer_Hidden In pips

extern string  Header10="----------Volatility Trailing Stops Settings-----------";
extern bool    UseVolTrailingStops=False;
extern double  VolTrailingDistMultiplier=6; // In units of ATR
extern double  VolTrailingBuffMultiplier=0; // In units of ATR

extern string  Header11="----------Hidden Volatility Trailing Stops Settings-----------";
extern bool    UseHiddenVolTrailing=False;
extern double  VolTrailingDistMultiplier_Hidden=0; // In units of ATR
extern double  VolTrailingBuffMultiplier_Hidden=0; // In units of ATR

extern string  Header12="----------Volatility Measurement Settings-----------";
extern int     atr_period=14;

extern string  Header13="----------Set Max Loss Limit-----------";
extern bool    IsLossLimitActivated=False;
extern double  LossLimitPercent=50;

extern string  Header14="----------Set Max Volatility Limit-----------";
extern bool    IsVolLimitActivated=False;
extern double  VolatilityMultiplier=3; // VolatilityMultiplier In units of ATR
extern int     ATRTimeframe=60; //ATRTimeframe In minutes
extern int     ATRPeriod=14;



string  InternalHeader1="----------Errors Handling Settings-----------";
int     RetryInterval=100; // Pause Time before next retry (in milliseconds)
int     MaxRetriesPerTick=10;

string  InternalHeader2="----------Service Variables-----------";

double Stop,Take;
double StopHidden,TakeHidden;
int    P;
int YenPairAdjustFactor;
double myATR;
double FastMA1, SlowMA1, Price1;

// Declaring Variables (and the extern variables above)

int CrossTriggered0, CrossTriggered1, CrossTriggered2, CrossTriggered3;
int candleType;

int OrderNumber;
double HiddenSLList[][2]; // First dimension is for position ticket numbers, second is for the SL Levels
double HiddenTPList[][2]; // First dimension is for position ticket numbers, second is for the TP Levels
double HiddenBEList[]; // First dimension is for position ticket numbers
double HiddenTrailingList[][2]; // First dimension is for position ticket numbers, second is for the hidden trailing stop levels
double VolTrailingList[][2]; // First dimension is for position ticket numbers, second is for recording of volatility amount (one unit of ATR) at the time of trade
double HiddenVolTrailingList[][3]; // First dimension is for position ticket numbers, second is for the hidden trailing stop levels, third is for recording of volatility amount (one unit of ATR) at the time of trade

string  InternalHeader3="----------Analytical Centre Variables-----------";
bool TradeAllowed = true;     // this will be commanded by Decision Support Centre
bool     isMarketTypePolicyON = true;
datetime ReferenceTime;       //used for order history
int     MyMarketType;         //used to receive market status from AI
bool BuyMarket = false;       //variables used to set specific market based on the Market Recognition function
bool SellMarket = false;
int Direction;                //variable to retrieve direction that is coming from the R script

string  InternalHeader4="----------ai knn Variables-----------";
double Prob_win_buy, Prob_win_sell;                                                      //define value for probabilities to win a trade
double base_buy[][v_dim_x];
double base_sell[][v_dim_x];

int numbers_of_vectors_buy=0;
int numbers_of_vectors_sell=0;

int Hadle_1, Hadle_2;       //defined files *.dat

//+------------------------------------------------------------------+
//| End of Setup                                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Initialization                                    
//+------------------------------------------------------------------+
int init()
  {
   
   ReferenceTime = TimeCurrent(); // record time for order history function
   
   //write file system control to enable initial trading
   TradeAllowed = ReadCommandFromCSV(MagicNumber);
      if(TradeAllowed == false)
     {
      Comment("Trade is not allowed");
     }
   else if(TradeAllowed == true)   // or file does not exist, create a new file
            {
               string fileName = "SystemControl"+string(MagicNumber)+".csv";//create the name of the file same for all symbols...
               // open file handle
               int handle = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE); FileSeek(handle,0,SEEK_END);
               string data = string(MagicNumber)+","+string(TerminalType);
               FileWrite(handle,data);  FileClose(handle);
               //end of writing to file
               Comment("Trade is allowed");
            }
   
      
   
   P=GetP(); // To account for 5 digit brokers. Used to convert pips to decimal place
   YenPairAdjustFactor=GetYenAdjustFactor(); // Adjust for YenPair

//----------(Hidden) TP, SL and Breakeven Stops Variables-----------  

// If EA disconnects abruptly and there are open positions from this EA, records form these arrays will be gone.
   if(UseHiddenStopLoss) ArrayResize(HiddenSLList,MaxPositionsAllowed,0);
   if(UseHiddenTakeProfit) ArrayResize(HiddenTPList,MaxPositionsAllowed,0);
   if(UseHiddenBreakevenStops) ArrayResize(HiddenBEList,MaxPositionsAllowed,0);
   if(UseHiddenTrailingStops) ArrayResize(HiddenTrailingList,MaxPositionsAllowed,0);
   if(UseVolTrailingStops) ArrayResize(VolTrailingList,MaxPositionsAllowed,0);
   if(UseHiddenVolTrailing) ArrayResize(HiddenVolTrailingList,MaxPositionsAllowed,0);


// Knn EA accomodation
if(!Base)
   {
      //1. for buy orders:
      if(TerminalType == 1) Hadle_1 = FileOpen("Buy_Position"+string(MagicNumber)+".dat",FILE_BIN|FILE_READ);
      //to make sure code will work in both terminals 3 and 4 by providing only 1 file e.g. Buy_Position8132100.dat
      if(TerminalType == 0 && T_Num(MagicNumber) == 3) Hadle_1 = FileOpen("Buy_Position"+string(MagicNumber-200)+".dat",FILE_BIN|FILE_READ);
      if(TerminalType == 0 && T_Num(MagicNumber) == 4) Hadle_1 = FileOpen("Buy_Position"+string(MagicNumber-300)+".dat",FILE_BIN|FILE_READ);
      
      ArrayResize(base_buy,FileSize(Hadle_1)/(v_dim_x*8));
      
      int count=0;
      while(!FileIsEnding(Hadle_1))
      {
         //on init we record values into the memory from file
         base_buy[count][0]=FileReadDouble(Hadle_1,DOUBLE_VALUE);
         base_buy[count][1]=FileReadDouble(Hadle_1,DOUBLE_VALUE);
         base_buy[count][2]=FileReadDouble(Hadle_1,DOUBLE_VALUE);
         base_buy[count][3]=FileReadDouble(Hadle_1,DOUBLE_VALUE);
         base_buy[count][4]=FileReadDouble(Hadle_1,DOUBLE_VALUE);
         base_buy[count][5]=FileReadDouble(Hadle_1,DOUBLE_VALUE);
         //Print(base_buy[count][5]);
         count++;
      }
      
      numbers_of_vectors_buy=count; //this records number of vectors available in the file (it will be used in the Euclidean function)
      
      if(TerminalType == 1) Hadle_2 = FileOpen("Sell_Position"+string(MagicNumber)+".dat",FILE_BIN|FILE_READ);
      //to make sure code will work in both terminals 3 and 4 by providing only 1 file e.g. Sell_Position8132100.dat
      if(TerminalType == 0 && T_Num(MagicNumber) == 3) Hadle_2 = FileOpen("Sell_Position"+string(MagicNumber-200)+".dat",FILE_BIN|FILE_READ);
      if(TerminalType == 0 && T_Num(MagicNumber) == 4) Hadle_2 = FileOpen("Sell_Position"+string(MagicNumber-300)+".dat",FILE_BIN|FILE_READ);
      
      ArrayResize(base_sell,FileSize(Hadle_2)/(v_dim_x*8));
      count=0;
      
      //2. for sell orders
      while(!FileIsEnding(Hadle_2))
      {
         base_sell[count][0]=FileReadDouble(Hadle_2,DOUBLE_VALUE);
         base_sell[count][1]=FileReadDouble(Hadle_2,DOUBLE_VALUE);
         base_sell[count][2]=FileReadDouble(Hadle_2,DOUBLE_VALUE);
         base_sell[count][3]=FileReadDouble(Hadle_2,DOUBLE_VALUE);
         base_sell[count][4]=FileReadDouble(Hadle_2,DOUBLE_VALUE);
         base_sell[count][5]=FileReadDouble(Hadle_2,DOUBLE_VALUE);
         //Print(base_sell[count][5]);
         count++;
      }
      numbers_of_vectors_sell=count;
   
   FileClose(Hadle_1);
   FileClose(Hadle_2);
   }
   
 
   start();
   return(0);
  }
//+------------------------------------------------------------------+
//| End of Expert Initialization                            
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Deinitialization                                  
//+------------------------------------------------------------------+
int deinit()
  {
//----Delete file InTrade...csv on deinitialization
FileDelete("InTrade"+string(MagicNumber)+".csv");
//----

//knn portion
//after the trade run during TESTER run we record results of the trades and corresponding status of vectors at the moment of opening trades
   if(Base)
   {
      Hadle_1=FileOpen("Buy_Position"+string(MagicNumber)+".dat",FILE_BIN|FILE_WRITE);
   
      int count;
      double ordinate_1,ordinate_2,ordinate_3,ordinate_4,ordinate_5;
   
      for(int i=OrdersHistoryTotal()-1;i>=0;i--)
      {
         OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
         if(OrderType()==0) //generate database for BUY orders
         {
            if(OrderProfit()>=0)//writing vectors to the database only for profitable orders
            {
               //write condition of indicators at the moment when trade was open
               count=iBarShift(Symbol(),Period(),OrderOpenTime());
               count++;//use bars before the orders were opened to forecast the probabilities
               //divide small value of indicator by higher value ??? why? it becomes a vector...
               ordinate_1=iMA(Symbol(),Period(),89,0,0,5,count)/iMA(Symbol(),Period(),144,0,0,5,count);
               ordinate_2=iMA(Symbol(),Period(),144,0,0,5,count)/iMA(Symbol(),Period(),233,0,0,5,count);
               ordinate_3=iMA(Symbol(),Period(),21,0,0,5,count)/iMA(Symbol(),Period(),89,0,0,5,count);
               ordinate_4=iMA(Symbol(),Period(),55,0,0,5,count)/iMA(Symbol(),Period(),89,0,0,5,count);
               ordinate_5=iMA(Symbol(),Period(),2,0,0,5,count)/iMA(Symbol(),Period(),55,0,0,5,count);
            
               FileWriteDouble(Hadle_1,ordinate_1,DOUBLE_VALUE);//writing to the file database...
               FileWriteDouble(Hadle_1,ordinate_2,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,ordinate_3,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,ordinate_4,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,ordinate_5,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,1,DOUBLE_VALUE);           //write label 1 as profit
            }
            if(OrderProfit()<0)//writing vectors to the database only for negative profit
            {
               count=iBarShift(Symbol(),Period(),OrderOpenTime());
               count++;//use bars before the orders were opened to forecast the probabilities
               ordinate_1=iMA(Symbol(),Period(),89,0,0,5,count)/iMA(Symbol(),Period(),144,0,0,5,count);
               ordinate_2=iMA(Symbol(),Period(),144,0,0,5,count)/iMA(Symbol(),Period(),233,0,0,5,count);
               ordinate_3=iMA(Symbol(),Period(),21,0,0,5,count)/iMA(Symbol(),Period(),89,0,0,5,count);
               ordinate_4=iMA(Symbol(),Period(),55,0,0,5,count)/iMA(Symbol(),Period(),89,0,0,5,count);
               ordinate_5=iMA(Symbol(),Period(),2,0,0,5,count)/iMA(Symbol(),Period(),55,0,0,5,count);
            
               FileWriteDouble(Hadle_1,ordinate_1,DOUBLE_VALUE);//writing to the file database...
               FileWriteDouble(Hadle_1,ordinate_2,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,ordinate_3,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,ordinate_4,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,ordinate_5,DOUBLE_VALUE);
               FileWriteDouble(Hadle_1,0,DOUBLE_VALUE);           //write label 0 as loss
            }
         }
      }
      Hadle_2=FileOpen("Sell_Position"+string(MagicNumber)+".dat",FILE_BIN|FILE_WRITE);
      for(int i=OrdersHistoryTotal()-1;i>=0;i--)
      {
         OrderSelect(i,SELECT_BY_POS,MODE_HISTORY);
         if(OrderType()==1) //generate database for SELL orders
         {
            if(OrderProfit()>=0)//writing vectors to the database only for profitable orders
            {
               count=iBarShift(Symbol(),Period(),OrderOpenTime());
               count++;//use bars before the orders were opened to forecast the probabilities
               ordinate_1=iMA(Symbol(),Period(),89,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),144,0,0,5,count));
               ordinate_2=iMA(Symbol(),Period(),144,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),233,0,0,5,count));
               ordinate_3=iMA(Symbol(),Period(),21,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),89,0,0,5,count));
               ordinate_4=iMA(Symbol(),Period(),55,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),89,0,0,5,count));
               ordinate_5=iMA(Symbol(),Period(),2,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),55,0,0,5,count));
            
               FileWriteDouble(Hadle_2,ordinate_1,DOUBLE_VALUE);//writing to the file database...
               FileWriteDouble(Hadle_2,ordinate_2,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,ordinate_3,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,ordinate_4,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,ordinate_5,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,1,DOUBLE_VALUE);           //write label 1 as profit
            }
            if(OrderProfit()<0)//writing vectors to the database only for negative profit
            {
               count=iBarShift(Symbol(),Period(),OrderOpenTime());
               count++;//use bars before the orders were opened to forecast the probabilities
               ordinate_1=iMA(Symbol(),Period(),89,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),144,0,0,5,count));
               ordinate_2=iMA(Symbol(),Period(),144,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),233,0,0,5,count));
               ordinate_3=iMA(Symbol(),Period(),21,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),89,0,0,5,count));
               ordinate_4=iMA(Symbol(),Period(),55,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),89,0,0,5,count));
               ordinate_5=iMA(Symbol(),Period(),2,0,0,5,count)/(0.0000001 + iMA(Symbol(),Period(),55,0,0,5,count));
            
               FileWriteDouble(Hadle_2,ordinate_1,DOUBLE_VALUE);//writing to the file database...
               FileWriteDouble(Hadle_2,ordinate_2,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,ordinate_3,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,ordinate_4,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,ordinate_5,DOUBLE_VALUE);
               FileWriteDouble(Hadle_2,0,DOUBLE_VALUE);           //write label 0 as loss
            }
         }
      }
   //Closing files after writing the data
   FileClose(Hadle_1);
   FileClose(Hadle_2);
   }
   
   return(0);
  }
//+------------------------------------------------------------------+
//| End of Expert Deinitialization                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert start                                             
//+------------------------------------------------------------------+
int start()
  {

   //interesting way to only execute code on ever new bar!!!
   if(!isNewBar())return(0);
   
   //----------Order management through R - to avoid slow down the system only enable with external parameters
   if(R_Management)
     {
         //code that only executed once a bar
      //   Direction = -1; //set direction to -1 by default in order to achieve cross!
         OrderProfitToCSV(T_Num(MagicNumber));                        //write previous orders profit results for auto analysis in R
         MyMarketType = ReadMarketFromCSV(Symbol(), 15);            //read analytical output from the Decision Support System   
      //get the Reinforcement Learning policy for specific Market Type
         if(TerminalType == 0 && use_market_type == true)
           {
            //this will return true/false value by interpreting the file generated by Reinforcement Learning
            isMarketTypePolicyON = CheckIfMarketTypePolicyIsOn(MagicNumber, MyMarketType);
           } else
               {
                isMarketTypePolicyON = true;
               }
       
       TradeAllowed = ReadCommandFromCSV(MagicNumber);              //read command from R to make sure trading is allowed
     }
   
   

//----------Variables to be Refreshed-----------

   OrderNumber=0; // OrderNumber used in Entry Rules

//----------Entry & Exit Variables-----------

   //define variables for trade entry...
   //double MACD_1=iMACD(Symbol(),Period(),fast,slow,9,PRICE_TYPICAL,0,1); //1 periods before
   //double MACD_2=iMACD(Symbol(),Period(),fast,slow,9,PRICE_TYPICAL,0,2); //2 periods before
   //double MACD_3=iMACD(Symbol(),Period(),fast,slow,9,PRICE_TYPICAL,0,3); //3 periods before...
   double MACD = iMACD(Symbol(),Period(),fast,slow,9,PRICE_TYPICAL,0,1);
   double MACDSignal =  iMACD(Symbol(),Period(),fast,slow,9,PRICE_TYPICAL,1,1);
   double KeltnerUpper1 = iCustom(NULL, 0, "Keltner_Channels", KeltnerPeriod, 0, 0, KeltnerPeriod, KeltnerMulti, True, 0, 1); // Shift 1
   double KeltnerLower1 = iCustom(NULL, 0, "Keltner_Channels", KeltnerPeriod, 0, 0, KeltnerPeriod, KeltnerMulti, True, 2, 1); // Shift 1
   double KeltnerMiddle = iCustom(NULL, 0, "Keltner_Channels", KeltnerPeriod, 0, 0, KeltnerPeriod, KeltnerMulti, True, 1, 1);
   double slowMA1 = iMA(Symbol(),Period(),233,0,0,5,1);
   
   double vector[5];                                                     //prepare array vector of dim 5

         vector[0]=iMA(Symbol(),Period(),89,0,0,5,1)/(0.0000001 + iMA(Symbol(),Period(),144,0,0,5,1));  //calculate indicators and put them to vector[5] array
         vector[1]=iMA(Symbol(),Period(),144,0,0,5,1)/(0.0000001 + iMA(Symbol(),Period(),233,0,0,5,1));
         vector[2]=iMA(Symbol(),Period(),21,0,0,5,1)/(0.0000001 + iMA(Symbol(),Period(),89,0,0,5,1));
         vector[3]=iMA(Symbol(),Period(),55,0,0,5,1)/(0.0000001 + iMA(Symbol(),Period(),89,0,0,5,1));
         vector[4]=iMA(Symbol(),Period(),2,0,0,5,1)/(0.0000001 + iMA(Symbol(),Period(),55,0,0,5,1));
    
    if(!Base) Prob_win_sell = Euclidean_Metric(base_sell,vector,numbers_of_vectors_sell);             //calculate Probabiltiy to win using function Euclidean_Metric...
    if(!Base) Prob_win_buy  = Euclidean_Metric(base_buy,vector, numbers_of_vectors_buy);             //calculate Probabiltiy to win using function Euclidean_Metric...  

      /*        
        If Output is 0: No cross happened
        If Output is 1: Line 1 crossed Line 2 from Bottom
        If Output is 2: Line 1 crossed Line 2 from top 
      */

    CrossTriggered0=Crossed0(Ask,KeltnerLower1);  //Value 1: price upcross keltnerlower, 2: price downcross keltnerlower
    CrossTriggered1=Crossed1(Bid ,KeltnerUpper1);  //Value 1: price upcross keltnerupper, 2: price downcross keltnerupper
    CrossTriggered2=Crossed2(Close[1],KeltnerMiddle);  //Value 1: price upcross keltnerupper, 2: price downcross keltnerupper
    CrossTriggered3=Crossed3(MACD,MACDSignal);
    
    int ExitBuySignal = 0;
    int ExitSellSignal = 0; 
    int EntryBuySignal = 0;
    int EntrySellSignal = 0;   
    
    if((CrossTriggered3==1) && (Ask < KeltnerUpper1))
    {
      EntryBuySignal = 1;
    }
    
     if((CrossTriggered3==2) && (Bid > KeltnerLower1))
    {
      EntrySellSignal = 1;
    }
    
    if(CrossTriggered0==1)
    {
      EntrySellSignal = 1;
    }
    
    if(CrossTriggered1==2)
    {
      EntryBuySignal = 1;
    }
        
//----------TP, SL, Breakeven and Trailing Stops Variables-----------

   myATR=iATR(NULL,Period(),atr_period,1);

   if(UseFixedStopLoss==False) 
     {
      Stop=0;
        }  else {
      Stop=VolBasedStopLoss(IsVolatilityStopOn,FixedStopLoss,myATR,VolBasedSLMultiplier,P);
     }

   if(UseFixedTakeProfit==False) 
     {
      Take=0;
        }  else {
      Take=VolBasedTakeProfit(IsVolatilityTakeProfitOn,FixedTakeProfit,myATR,VolBasedTPMultiplier,P);
     }

   if(UseBreakevenStops) BreakevenStopAll(OnJournaling,RetryInterval,BreakevenBuffer,MagicNumber,P);
   if(UseTrailingStops) TrailingStopAll(OnJournaling,TrailingStopDistance,TrailingStopBuffer,RetryInterval,MagicNumber,P);
   if(UseVolTrailingStops) {
      UpdateVolTrailingList(OnJournaling,RetryInterval,MagicNumber);
      ReviewVolTrailingStop(OnJournaling,VolTrailingDistMultiplier,VolTrailingBuffMultiplier,RetryInterval,MagicNumber,P);
   }
//----------(Hidden) TP, SL, Breakeven and Trailing Stops Variables-----------  

   if(UseHiddenStopLoss) TriggerStopLossHidden(OnJournaling,RetryInterval,MagicNumber,Slippage,P);
   if(UseHiddenTakeProfit) TriggerTakeProfitHidden(OnJournaling,RetryInterval,MagicNumber,Slippage,P);
   if(UseHiddenBreakevenStops) { 
      UpdateHiddenBEList(OnJournaling,RetryInterval,MagicNumber);
      SetAndTriggerBEHidden(OnJournaling,BreakevenBuffer,MagicNumber,Slippage,P,RetryInterval);
   }
   if(UseHiddenTrailingStops) {
      UpdateHiddenTrailingList(OnJournaling,RetryInterval,MagicNumber);
      SetAndTriggerHiddenTrailing(OnJournaling,TrailingStopDistance_Hidden,TrailingStopBuffer_Hidden,Slippage,RetryInterval,MagicNumber,P);
   }
   if(UseHiddenVolTrailing) {
      UpdateHiddenVolTrailingList(OnJournaling,RetryInterval,MagicNumber);
      TriggerAndReviewHiddenVolTrailing(OnJournaling,VolTrailingDistMultiplier_Hidden,VolTrailingBuffMultiplier_Hidden,Slippage,RetryInterval,MagicNumber,P);
   }

//----------Exit Rules (All Opened Positions)-----------
   // TDL 2: Setting up Exit rules. Modify the ExitSignal() function to suit your needs.
if(Base)
  {
      //in test mode
      if(CountPosOrders(MagicNumber,OP_BUY)>=1 && (ExitBuySignal==1) && close_orders)
        { // Close Long Positions
         CloseOrderPosition(OP_BUY, OnJournaling, MagicNumber, Slippage, P, RetryInterval); 
        }
      if(CountPosOrders(MagicNumber,OP_SELL)>=1 && (ExitSellSignal==1) && close_orders)
        { // Close Short Positions
         CloseOrderPosition(OP_SELL, OnJournaling, MagicNumber, Slippage, P, RetryInterval);
        }
  }

if(!Base)
  {
   //in trading mode
      if(CountPosOrders(MagicNumber,OP_BUY)>=1 && (ExitBuySignal==1) && close_orders)
        { // Close Long Positions
         CloseOrderPosition(OP_BUY, OnJournaling, MagicNumber, Slippage, P, RetryInterval); 
        }
      if(CountPosOrders(MagicNumber,OP_SELL)>=1 && (ExitSellSignal==1) && close_orders)
        { // Close Short Positions
         CloseOrderPosition(OP_SELL, OnJournaling, MagicNumber, Slippage, P, RetryInterval);
        }
  }

//----------Entry Rules (Market and Pending) -----------
   if(IsLossLimitBreached(IsLossLimitActivated,LossLimitPercent,OnJournaling,EntrySignal(CrossTriggered0))==False)
      if(IsVolLimitBreached(IsVolLimitActivated,VolatilityMultiplier,ATRTimeframe,ATRPeriod)==False)
         if(IsMaxPositionsReached(MaxPositionsAllowed,MagicNumber,OnJournaling)==False)
           {
            //order opening in TESTING   
            if(Base && (EntryBuySignal==1))
              { // Open Long Positions
               OrderNumber=OpenPositionMarket(OP_BUY,GetLot(IsSizingOn,Lots,Risk,YenPairAdjustFactor,Stop,P),Stop,Take,MagicNumber,Slippage,OnJournaling,P,IsECNbroker,MaxRetriesPerTick,RetryInterval);
               // Set Stop Loss value for Hidden SL
               if(UseHiddenStopLoss) SetStopLossHidden(OnJournaling,IsVolatilityStopLossOn_Hidden,FixedStopLoss_Hidden,myATR,VolBasedSLMultiplier_Hidden,P,OrderNumber);
               // Set Take Profit value for Hidden TP
               if(UseHiddenTakeProfit) SetTakeProfitHidden(OnJournaling,IsVolatilityTakeProfitOn_Hidden,FixedTakeProfit_Hidden,myATR,VolBasedTPMultiplier_Hidden,P,OrderNumber);
               // Set Volatility Trailing Stop Level           
               if(UseVolTrailingStops) SetVolTrailingStop(OnJournaling,RetryInterval,myATR,VolTrailingDistMultiplier,MagicNumber,P,OrderNumber);
               // Set Hidden Volatility Trailing Stop Level 
               if(UseHiddenVolTrailing) SetHiddenVolTrailing(OnJournaling,myATR,VolTrailingDistMultiplier_Hidden,MagicNumber,P,OrderNumber);
              }
   
            if(Base && (EntrySellSignal==1))
              { // Open Short Positions
               OrderNumber=OpenPositionMarket(OP_SELL,GetLot(IsSizingOn,Lots,Risk,YenPairAdjustFactor,Stop,P),Stop,Take,MagicNumber,Slippage,OnJournaling,P,IsECNbroker,MaxRetriesPerTick,RetryInterval);
   
               // Set Stop Loss value for Hidden SL
               if(UseHiddenStopLoss) SetStopLossHidden(OnJournaling,IsVolatilityStopLossOn_Hidden,FixedStopLoss_Hidden,myATR,VolBasedSLMultiplier_Hidden,P,OrderNumber);
   
               // Set Take Profit value for Hidden TP
               if(UseHiddenTakeProfit) SetTakeProfitHidden(OnJournaling,IsVolatilityTakeProfitOn_Hidden,FixedTakeProfit_Hidden,myATR,VolBasedTPMultiplier_Hidden,P,OrderNumber);
               
               // Set Volatility Trailing Stop Level 
               if(UseVolTrailingStops) SetVolTrailingStop(OnJournaling,RetryInterval,myATR,VolTrailingDistMultiplier,MagicNumber,P,OrderNumber);
                
               // Set Hidden Volatility Trailing Stop Level  
               if(UseHiddenVolTrailing) SetHiddenVolTrailing(OnJournaling,myATR,VolTrailingDistMultiplier_Hidden,MagicNumber,P,OrderNumber);
             
              }
            
            //order opening in TRADING
            //if(TradeAllowed && Prob_win>=buy_threshold)OrderSend(Symbol(),OP_BUY,0.01,Ask,3,Bid-sl*Point,Ask+tp*Point);
            //if(TradeAllowed && inverse_position_open && Prob_win<=invers_buy_threshold)OrderSend(Symbol(),OP_SELL,0.01,Bid,3,Ask+sl*Point,Bid-tp*Point);
            if(!Base && TradeAllowed && isMarketTypePolicyON && (Prob_win_buy >= buy_threshold || (inverse_position_open && Prob_win_sell <= invers_sell_threshold)) &&
               (EntryBuySignal==1)) 
              { // Open Long Positions
               OrderNumber=OpenPositionMarket(OP_BUY,GetLot(IsSizingOn,Lots,Risk,YenPairAdjustFactor,Stop,P),Stop,Take,MagicNumber,Slippage,OnJournaling,P,IsECNbroker,MaxRetriesPerTick,RetryInterval);
               
               // Log current MarketType to the file in the sandbox
               LogMarketType(MagicNumber, OrderNumber, MyMarketType);
               
               // Set Stop Loss value for Hidden SL
               if(UseHiddenStopLoss) SetStopLossHidden(OnJournaling,IsVolatilityStopLossOn_Hidden,FixedStopLoss_Hidden,myATR,VolBasedSLMultiplier_Hidden,P,OrderNumber);
   
               // Set Take Profit value for Hidden TP
               if(UseHiddenTakeProfit) SetTakeProfitHidden(OnJournaling,IsVolatilityTakeProfitOn_Hidden,FixedTakeProfit_Hidden,myATR,VolBasedTPMultiplier_Hidden,P,OrderNumber);
               
               // Set Volatility Trailing Stop Level           
               if(UseVolTrailingStops) SetVolTrailingStop(OnJournaling,RetryInterval,myATR,VolTrailingDistMultiplier,MagicNumber,P,OrderNumber);
               
               // Set Hidden Volatility Trailing Stop Level 
               if(UseHiddenVolTrailing) SetHiddenVolTrailing(OnJournaling,myATR,VolTrailingDistMultiplier_Hidden,MagicNumber,P,OrderNumber);
             
              }
            //if(TradeAllowed && Prob_win >= sell_threshold)OrderSend(Symbol(),OP_SELL,0.01,Bid,3,Ask+sl*Point,Bid-tp*Point);
            //if(TradeAllowed && inverse_position_open && Prob_win<=invers_sell_threshold)OrderSend(Symbol(),OP_BUY,0.01,Ask,3,Bid-sl*Point,Ask+tp*Point);
            if(!Base && TradeAllowed && isMarketTypePolicyON && (Prob_win_sell >= sell_threshold || (inverse_position_open && Prob_win_buy <= invers_buy_threshold)) && 
               (EntrySellSignal==1))
              { // Open Short Positions
               OrderNumber=OpenPositionMarket(OP_SELL,GetLot(IsSizingOn,Lots,Risk,YenPairAdjustFactor,Stop,P),Stop,Take,MagicNumber,Slippage,OnJournaling,P,IsECNbroker,MaxRetriesPerTick,RetryInterval);
               // Log current MarketType to the file in the sandbox
               LogMarketType(MagicNumber, OrderNumber, MyMarketType);
               // Set Stop Loss value for Hidden SL
               if(UseHiddenStopLoss) SetStopLossHidden(OnJournaling,IsVolatilityStopLossOn_Hidden,FixedStopLoss_Hidden,myATR,VolBasedSLMultiplier_Hidden,P,OrderNumber);
               // Set Take Profit value for Hidden TP
               if(UseHiddenTakeProfit) SetTakeProfitHidden(OnJournaling,IsVolatilityTakeProfitOn_Hidden,FixedTakeProfit_Hidden,myATR,VolBasedTPMultiplier_Hidden,P,OrderNumber);
               // Set Volatility Trailing Stop Level 
               if(UseVolTrailingStops) SetVolTrailingStop(OnJournaling,RetryInterval,myATR,VolTrailingDistMultiplier,MagicNumber,P,OrderNumber);
               // Set Hidden Volatility Trailing Stop Level  
               if(UseHiddenVolTrailing) SetHiddenVolTrailing(OnJournaling,myATR,VolTrailingDistMultiplier_Hidden,MagicNumber,P,OrderNumber);
              }  
           }

//----------Pending Order Management-----------
/*
        Not Applicable (See Desiree for example of pending order rules).
   */

//----    

    //adding dashboard
    if(EnableDashboard==True) ShowDashboard("MarketType", MagicNumber,
                                            "xxx", 0,
                                            "Prob_win_buy", Prob_win_buy,
                                            "xxx", 0,
                                            "Prob_win_sell", Prob_win_sell,
                                            "xxx", 0,
                                            "xxx", 0); 

   return(0);
  }
//+------------------------------------------------------------------+
//| End of expert start function                                     |
//+------------------------------------------------------------------+

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//|                     FUNCTIONS LIBRARY                                   
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*

Content:
1) EntrySignal
2) ExitSignal
3) GetLot
4) CheckLot
5) CountPosOrders
6) IsMaxPositionsReached
7) OpenPositionMarket
8) OpenPositionPending
9) CloseOrderPosition
10) GetP
11) GetYenAdjustFactor
12) VolBasedStopLoss
13) VolBasedTakeProfit
14) Crossed1 / Crossed2
15) IsLossLimitBreached
16) IsVolLimitBreached
17) SetStopLossHidden
18) TriggerStopLossHidden
19) SetTakeProfitHidden
20) TriggerTakeProfitHidden
21) BreakevenStopAll
22) UpdateHiddenBEList
23) SetAndTriggerBEHidden
24) TrailingStopAll
25) UpdateHiddenTrailingList
26) SetAndTriggerHiddenTrailing
27) UpdateVolTrailingList
28) SetVolTrailingStop
29) ReviewVolTrailingStop
30) UpdateHiddenVolTrailingList
31) SetHiddenVolTrailing
32) TriggerAndReviewHiddenVolTrailing
33) HandleTradingEnvironment
34) GetErrorDescription
35) ReadAutoPrediction

*/


//+------------------------------------------------------------------+
//| ENTRY SIGNAL                                                     |
//+------------------------------------------------------------------+
int EntrySignal(int CrossOccurred)
  {
// Type: Customisable 
// Modify this function to suit your trading robot

// This function checks for entry signals
   int   entryOutput=0;
   if(CrossOccurred==1) entryOutput=1; 
   if(CrossOccurred==2) entryOutput=2;
   return(entryOutput);
  }
//+------------------------------------------------------------------+
//| End of ENTRY SIGNAL                                              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Exit SIGNAL                                                      |
//+------------------------------------------------------------------+
int ExitSignal(int CrossOccurred)
  {
// Type: Customisable 
// Modify this function to suit your trading robot

// This function checks for exit signals
   int   ExitOutput=0;
   if(CrossOccurred==1) ExitOutput=1;
   if(CrossOccurred==2) ExitOutput=2;
   return(ExitOutput);
  }
//+------------------------------------------------------------------+
//| End of Exit SIGNAL                                               
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Position Sizing Algo               
//+------------------------------------------------------------------+
// Type: Customisable 
// Modify this function to suit your trading robot

// This is our sizing algorithm

double GetLot(bool IsSizingOnTrigger,double FixedLots,double RiskPerTrade,int YenAdjustment,double STOP,int K) 
  {

   double output;

   if(IsSizingOnTrigger==true) 
     {
      output=RiskPerTrade*0.01*AccountBalance()/(MarketInfo(Symbol(),MODE_LOTSIZE)*MarketInfo(Symbol(),MODE_TICKVALUE)*STOP*K*Point); // Sizing Algo based on account size
      output=output*YenAdjustment; // Adjust for Yen Pairs
        } else {
      output=FixedLots;
     }
   output=NormalizeDouble(output,2); // Round to 2 decimal place
   return(output);
  }
//+------------------------------------------------------------------+
//| End of Position Sizing Algo               
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| CHECK LOT
//+------------------------------------------------------------------+
double CheckLot(double Lot,bool Journaling)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function checks if our Lots to be trade satisfies any broker limitations

   double LotToOpen=0;
   LotToOpen=NormalizeDouble(Lot,2);
   LotToOpen=MathFloor(LotToOpen/MarketInfo(Symbol(),MODE_LOTSTEP))*MarketInfo(Symbol(),MODE_LOTSTEP);

   if(LotToOpen<MarketInfo(Symbol(),MODE_MINLOT))LotToOpen=MarketInfo(Symbol(),MODE_MINLOT);
   if(LotToOpen>MarketInfo(Symbol(),MODE_MAXLOT))LotToOpen=MarketInfo(Symbol(),MODE_MAXLOT);
   LotToOpen=NormalizeDouble(LotToOpen,2);

   if(Journaling && LotToOpen!=Lot)Print("EA Journaling: Trading Lot has been changed by CheckLot function. Requested lot: "+(string)Lot+". Lot to open: "+(string)LotToOpen);

   return(LotToOpen);
  }
//+------------------------------------------------------------------+
//| End of CHECK LOT
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| COUNT POSITIONS 
//+------------------------------------------------------------------+
int CountPosOrders(int Magic,int TYPE)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function counts number of positions/orders of OrderType TYPE

   int Orders=0;
   for(int i=0; i<OrdersTotal(); i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==TYPE)
         Orders++;
     }
   return(Orders);

  }
//+------------------------------------------------------------------+
//| End of COUNT POSITIONS
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| MAX ORDERS                                              
//+------------------------------------------------------------------+
bool IsMaxPositionsReached(int MaxPositions,int Magic,bool Journaling)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function checks the number of positions we are holding against the maximum allowed 

   int result=False;
   if(CountPosOrders(Magic,OP_BUY)+CountPosOrders(Magic,OP_SELL)>MaxPositions) 
     {
      result=True;
      if(Journaling)Print("Max Orders Exceeded");
        } else if(CountPosOrders(Magic,OP_BUY)+CountPosOrders(Magic,OP_SELL)==MaxPositions) {
      result=True;
     }

   return(result);

/* Definitions: Position vs Orders
   
   Position describes an opened trade
   Order is a pending trade
   
   How to use in a sentence: Jim has 5 buy limit orders pending 10 minutes ago. The market just crashed. The orders were executed and he has 5 losing positions now lol.

*/
  }
//+------------------------------------------------------------------+
//| End of MAX ORDERS                                                
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| OPEN FROM MARKET
//+------------------------------------------------------------------+
int OpenPositionMarket(int TYPE,double LOT,double SL,double TP,int Magic,int Slip,bool Journaling,int K,bool ECN,int Max_Retries_Per_Tick,int Retry_Interval)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function submits new orders

   int tries=0;
   string symbol=Symbol();
   int cmd=TYPE;
   double volume=CheckLot(LOT,Journaling);
   if(MarketInfo(symbol,MODE_MARGINREQUIRED)*volume>AccountFreeMargin())
     {
      Print("Can not open a trade. Not enough free margin to open "+(string)volume+" on "+symbol);
      return(-1);
     }
   int slippage=Slip*K; // Slippage is in points. 1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
   string comment=" "+(string)TYPE+"(#"+(string)Magic+")";
   int magic=Magic;
   datetime expiration=0;
   color arrow_color=0;if(TYPE==OP_BUY)arrow_color=Blue;if(TYPE==OP_SELL)arrow_color=Green;
   double stoploss=0;
   double takeprofit=0;
   double initTP = TP;
   double initSL = SL;
   int Ticket=-1;
   double price=0;
   if(!ECN)
     {
      while(tries<Max_Retries_Per_Tick) // Edits stops and take profits before the market order is placed
        {
         RefreshRates();
         if(TYPE==OP_BUY)price=Ask;if(TYPE==OP_SELL)price=Bid;

         // Sets Take Profits and Stop Loss. Check against Stop Level Limitations.
         if(TYPE==OP_BUY && SL!=0)
           {
            stoploss=NormalizeDouble(Ask-SL*K*Point,Digits);
            if(Bid-stoploss<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
              {
               stoploss=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from "+(string)initSL+" to "+string(MarketInfo(Symbol(),MODE_STOPLEVEL)/K)+" pips");
              }
           }
         if(TYPE==OP_SELL && SL!=0)
           {
            stoploss=NormalizeDouble(Bid+SL*K*Point,Digits);
            if(stoploss-Ask<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
              {
               stoploss=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Stop Loss changed from "+(string)initSL+" to "+string(MarketInfo(Symbol(),MODE_STOPLEVEL)/K)+" pips");
              }
           }
         if(TYPE==OP_BUY && TP!=0)
           {
            takeprofit=NormalizeDouble(Ask+TP*K*Point,Digits);
            if(takeprofit-Bid<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
              {
               takeprofit=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from "+(string)initTP+" to "+string(MarketInfo(Symbol(),MODE_STOPLEVEL)/K)+" pips");
              }
           }
         if(TYPE==OP_SELL && TP!=0)
           {
            takeprofit=NormalizeDouble(Bid-TP*K*Point,Digits);
            if(Ask-takeprofit<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
              {
               takeprofit=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
               if(Journaling)Print("EA Journaling: Take Profit changed from "+(string)initTP+" to "+string(MarketInfo(Symbol(),MODE_STOPLEVEL)/K)+" pips");
              }
           }
         if(Journaling)Print("EA Journaling: Trying to place a market order...");
         HandleTradingEnvironment(Journaling,Retry_Interval);
         Ticket=OrderSend(symbol,cmd,volume,price,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
         if(Ticket>0)break;
         tries++;
        }
     }
   if(ECN) // Edits stops and take profits after the market order is placed
     {
      HandleTradingEnvironment(Journaling,Retry_Interval);
      if(TYPE==OP_BUY)price=Ask;if(TYPE==OP_SELL)price=Bid;
      if(Journaling)Print("EA Journaling: Trying to place a market order...");
      Ticket=OrderSend(symbol,cmd,volume,price,slippage,0,0,comment,magic,expiration,arrow_color);
      if(Ticket>0)
         if(Ticket>0 && OrderSelect(Ticket,SELECT_BY_TICKET)==true && (SL!=0 || TP!=0))
           {
            // Sets Take Profits and Stop Loss. Check against Stop Level Limitations.
            if(TYPE==OP_BUY && SL!=0)
              {
               stoploss=NormalizeDouble(OrderOpenPrice()-SL*K*Point,Digits);
               if(Bid-stoploss<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
                 {
                  stoploss=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
                  if(Journaling)Print("EA Journaling: Stop Loss changed from "+(string)initSL+" to "+string((OrderOpenPrice()-stoploss)/(K*Point))+" pips");
                 }
              }
            if(TYPE==OP_SELL && SL!=0)
              {
               stoploss=NormalizeDouble(OrderOpenPrice()+SL*K*Point,Digits);
               if(stoploss-Ask<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
                 {
                  stoploss=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
                  if(Journaling)Print("EA Journaling: Stop Loss changed from "+(string)initSL+" to "+string((stoploss-OrderOpenPrice())/(K*Point))+" pips");
                 }
              }
            if(TYPE==OP_BUY && TP!=0)
              {
               takeprofit=NormalizeDouble(OrderOpenPrice()+TP*K*Point,Digits);
               if(takeprofit-Bid<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
                 {
                  takeprofit=NormalizeDouble(Ask+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
                  if(Journaling)Print("EA Journaling: Take Profit changed from "+(string)initTP+" to "+string((takeprofit-OrderOpenPrice())/(K*Point))+" pips");
                 }
              }
            if(TYPE==OP_SELL && TP!=0)
              {
               takeprofit=NormalizeDouble(OrderOpenPrice()-TP*K*Point,Digits);
               if(Ask-takeprofit<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
                 {
                  takeprofit=NormalizeDouble(Bid-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
                  if(Journaling)Print("EA Journaling: Take Profit changed from "+(string)initTP+" to "+string((OrderOpenPrice()-takeprofit)/(K*Point))+" pips");
                 }
              }
            bool ModifyOpen=false;
            while(!ModifyOpen)
              {
               HandleTradingEnvironment(Journaling,Retry_Interval);
               ModifyOpen=OrderModify(Ticket,OrderOpenPrice(),stoploss,takeprofit,expiration,arrow_color);
               if(Journaling && !ModifyOpen)Print("EA Journaling: Take Profit and Stop Loss not set. Error Description: "+GetErrorDescription(GetLastError()));
              }
           }
     }
   if(Journaling && Ticket<0)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
   if(Journaling && Ticket>0)
     {
      Print("EA Journaling: Order successfully placed. Ticket: "+(string)Ticket);
     }
   return(Ticket);
  }
//+------------------------------------------------------------------+
//| End of OPEN FROM MARKET   
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| OPEN PENDING ORDERS
//+------------------------------------------------------------------+
int OpenPositionPending(int TYPE,double OpenPrice,datetime expiration,double LOT,double SL,double TP,int Magic,int Slip,bool Journaling,int K,bool ECN,int Max_Retries_Per_Tick,int Retry_Interval)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function submits new pending orders
   OpenPrice= NormalizeDouble(OpenPrice,Digits);
   int tries=0;
   string symbol=Symbol();
   int cmd=TYPE;
   double volume=CheckLot(LOT,Journaling);
   if(MarketInfo(symbol,MODE_MARGINREQUIRED)*volume>AccountFreeMargin())
     {
      Print("Can not open a trade. Not enough free margin to open "+(string)volume+" on "+symbol);
      return(-1);
     }
   int slippage=Slip*K; // Slippage is in points. 1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
   string comment=" "+(string)TYPE+"(#"+(string)Magic+")";
   int magic=Magic;
   color arrow_color=0;if(TYPE==OP_BUYLIMIT || TYPE==OP_BUYSTOP)arrow_color=Blue;if(TYPE==OP_SELLLIMIT || TYPE==OP_SELLSTOP)arrow_color=Green;
   double stoploss=0;
   double takeprofit=0;
   double initTP = TP;
   double initSL = SL;
   int Ticket=-1;
   double price=0;

   while(tries<Max_Retries_Per_Tick) // Edits stops and take profits before the market order is placed
     {
      RefreshRates();

      // We are able to send in TP and SL when we open our orders even if we are using ECN brokers

      // Sets Take Profits and Stop Loss. Check against Stop Level Limitations.
      if((TYPE==OP_BUYLIMIT || TYPE==OP_BUYSTOP) && SL!=0)
        {
         stoploss=NormalizeDouble(OpenPrice-SL*K*Point,Digits);
         if(OpenPrice-stoploss<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
           {
            stoploss=NormalizeDouble(OpenPrice-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
            if(Journaling)Print("EA Journaling: Stop Loss changed from "+(string)initSL+" to "+string((OpenPrice-stoploss)/(K*Point))+" pips");
           }
        }
      if((TYPE==OP_BUYLIMIT || TYPE==OP_BUYSTOP) && TP!=0)
        {
         takeprofit=NormalizeDouble(OpenPrice+TP*K*Point,Digits);
         if(takeprofit-OpenPrice<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
           {
            takeprofit=NormalizeDouble(OpenPrice+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
            if(Journaling)Print("EA Journaling: Take Profit changed from "+(string)initTP+" to "+string((takeprofit-OpenPrice)/(K*Point))+" pips");
           }
        }
      if((TYPE==OP_SELLLIMIT || TYPE==OP_SELLSTOP) && SL!=0)
        {
         stoploss=NormalizeDouble(OpenPrice+SL*K*Point,Digits);
         if(stoploss-OpenPrice<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
           {
            stoploss=NormalizeDouble(OpenPrice+MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
            if(Journaling)Print("EA Journaling: Stop Loss changed from " + (string)initSL + " to " + string((stoploss-OpenPrice)/(K*Point)) + " pips");
           }
        }
      if((TYPE==OP_SELLLIMIT || TYPE==OP_SELLSTOP) && TP!=0)
        {
         takeprofit=NormalizeDouble(OpenPrice-TP*K*Point,Digits);
         if(OpenPrice-takeprofit<=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point) 
           {
            takeprofit=NormalizeDouble(OpenPrice-MarketInfo(Symbol(),MODE_STOPLEVEL)*Point,Digits);
            if(Journaling)Print("EA Journaling: Take Profit changed from " + (string)initTP + " to " + string((OpenPrice-takeprofit)/(K*Point)) + " pips");
           }
        }
      if(Journaling)Print("EA Journaling: Trying to place a pending order...");
      HandleTradingEnvironment(Journaling,Retry_Interval);

      //Note: We did not modify Open Price if it breaches the Stop Level Limitations as Open Prices are sensitive and important. It is unsafe to change it automatically.
      Ticket=OrderSend(symbol,cmd,volume,OpenPrice,slippage,stoploss,takeprofit,comment,magic,expiration,arrow_color);
      if(Ticket>0)break;
      tries++;
     }

   if(Journaling && Ticket<0)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
   if(Journaling && Ticket>0)
     {
      Print("EA Journaling: Order successfully placed. Ticket: "+(string)Ticket);
     }
   return(Ticket);
  }
//+------------------------------------------------------------------+
//| End of OPEN PENDING ORDERS 
//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
//| CLOSE/DELETE ORDERS AND POSITIONS
//+------------------------------------------------------------------+
bool CloseOrderPosition(int TYPE,bool Journaling,int Magic,int Slip,int K,int Retry_Interval)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function closes all positions of type TYPE or Deletes pending orders of type TYPE
   int ordersPos=OrdersTotal();

   for(int i=ordersPos-1; i>=0; i--)
     {
      // Note: Once pending orders become positions, OP_BUYLIMIT AND OP_BUYSTOP becomes OP_BUY, OP_SELLLIMIT and OP_SELLSTOP becomes OP_SELL
      if(TYPE==OP_BUY || TYPE==OP_SELL)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==TYPE)
           {
            bool Closing=false;
            double Price=0;
            color arrow_color=0;if(TYPE==OP_BUY)arrow_color=Blue;if(TYPE==OP_SELL)arrow_color=Green;
            if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,RetryInterval);
            if(TYPE==OP_BUY)Price=Bid; if(TYPE==OP_SELL)Price=Ask;
            Closing=OrderClose(OrderTicket(),OrderLots(),Price,Slip*K,arrow_color);
            if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Closing)Print("EA Journaling: Position successfully closed.");
           }
        }
      else
        {
         bool Delete=false;
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==TYPE)
           {
            if(Journaling)Print("EA Journaling: Trying to delete order "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,RetryInterval);
            Delete=OrderDelete(OrderTicket(),CLR_NONE);
            if(Journaling && !Delete)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Delete)Print("EA Journaling: Order successfully deleted.");
           }
        }
     }
   if(CountPosOrders(Magic, TYPE)==0)return(true); else return(false);
  }
//+------------------------------------------------------------------+
//| End of CLOSE/DELETE ORDERS AND POSITIONS 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Check for 4/5 Digits Broker              
//+------------------------------------------------------------------+ 
int GetP() 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns P, which is used for converting pips to decimals/points

   int output;
   if(Digits==5 || Digits==3) output=10;else output=1;
   return(output);

/* Some definitions: Pips vs Point

1 pip = 0.0001 on a 4 digit broker and 0.00010 on a 5 digit broker
1 point = 0.0001 on 4 digit broker and 0.00001 on a 5 digit broker
  
*/

  }
//+------------------------------------------------------------------+
//| End of Check for 4/5 Digits Broker               
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Yen Adjustment Factor             
//+------------------------------------------------------------------+ 
int GetYenAdjustFactor() 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns a constant factor, which is used for position sizing for Yen pairs

   int output= 1;
   if(Digits == 3|| Digits == 2) output = 100;
   return(output);
  }
//+------------------------------------------------------------------+
//| End of Yen Adjustment Factor             
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Volatility-Based Stop Loss                                             
//+------------------------------------------------------------------+
double VolBasedStopLoss(bool isVolatilitySwitchOn,double fixedStop,double VolATR,double volMultiplier,int K)
  { // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates stop loss amount based on volatility

   double StopL;
   if(!isVolatilitySwitchOn)
     {
      StopL=fixedStop; // If Volatility Stop Loss not activated. Stop Loss = Fixed Pips Stop Loss
        } else {
      StopL=volMultiplier*VolATR/(K*Point); // Stop Loss in Pips
     }
   return(StopL);
  }
//+------------------------------------------------------------------+
//| End of Volatility-Based Stop Loss                  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Volatility-Based Take Profit                                     
//+------------------------------------------------------------------+

double VolBasedTakeProfit(bool isVolatilitySwitchOn,double fixedTP,double VolATR,double volMultiplier,int K)
  { // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates take profit amount based on volatility

   double TakeP;
   if(!isVolatilitySwitchOn)
     {
      TakeP=fixedTP; // If Volatility Take Profit not activated. Take Profit = Fixed Pips Take Profit
        } else {
      TakeP=volMultiplier*VolATR/(K*Point); // Take Profit in Pips
     }
   return(TakeP);
  }
//+------------------------------------------------------------------+
//| End of Volatility-Based Take Profit                 
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Cross0                                                             
//+------------------------------------------------------------------+

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if a cross happened between 2 lines/data set
// Current version of EA does execution once x bar static vars not used
/* 

If Output is 0: No cross happened
If Output is 1: Line 1 crossed Line 2 from Bottom
If Output is 2: Line 1 crossed Line 2 from top 

*/

int Crossed0(double line1,double line2)
{

   static int CurrentDirection1=0;
   static int LastDirection1=0;
   static bool FirstTime1=true;

//----
   if(line1>line2)
      CurrentDirection1=1;  // line1 above line2
   if(line1<line2)
      CurrentDirection1=2;  // line1 below line2
//----
   if(FirstTime1==true) // Need to check if this is the first time the function is run
     {
      FirstTime1=false; // Change variable to false
      LastDirection1=CurrentDirection1; // Set new direction
      return (0);
     }

   if(CurrentDirection1!=LastDirection1 && FirstTime1==false) // If not the first time and there is a direction change
     {
      LastDirection1=CurrentDirection1; // Set new direction
      return(CurrentDirection1); // 1 for up, 2 for down
     }
   else
     {
      return(0);  // No direction change
     }  
  }
//+------------------------------------------------------------------+
// End of Cross                                                      
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Cross1                                                             
//+------------------------------------------------------------------+

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if a cross happened between 2 lines/data set
// Current version of EA does execution once x bar static vars not used
/* 

If Output is 0: No cross happened
If Output is 1: Line 1 crossed Line 2 from Bottom
If Output is 2: Line 1 crossed Line 2 from top 

*/

int Crossed1(double line1,double line2)
  {

   static int CurrentDirection1=0;
   static int LastDirection1=0;
   static bool FirstTime1=true;

//----
   if(line1>line2)
      CurrentDirection1=1;  // line1 above line2
   if(line1<line2)
      CurrentDirection1=2;  // line1 below line2
//----
   if(FirstTime1==true) // Need to check if this is the first time the function is run
     {
      FirstTime1=false; // Change variable to false
      LastDirection1=CurrentDirection1; // Set new direction
      return (0);
     }

   if(CurrentDirection1!=LastDirection1 && FirstTime1==false) // If not the first time and there is a direction change
     {
      LastDirection1=CurrentDirection1; // Set new direction
      return(CurrentDirection1); // 1 for up, 2 for down
     }
   else
     {
      return(0);  // No direction change
     }
  }
//+------------------------------------------------------------------+
// End of Cross                                                      
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Cross2                                                             
//+------------------------------------------------------------------+

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if a cross happened between 2 lines/data set
// Current version of EA does execution once x bar static vars not used
/* 

If Output is 0: No cross happened
If Output is 1: Line 1 crossed Line 2 from Bottom
If Output is 2: Line 1 crossed Line 2 from top 

*/

int Crossed2(double line1,double line2)
  {

   static int CurrentDirection1=0;
   static int LastDirection1=0;
   static bool FirstTime1=true;

//----
   if(line1>line2)
      CurrentDirection1=1;  // line1 above line2
   if(line1<line2)
      CurrentDirection1=2;  // line1 below line2
//----
   if(FirstTime1==true) // Need to check if this is the first time the function is run
     {
      FirstTime1=false; // Change variable to false
      LastDirection1=CurrentDirection1; // Set new direction
      return (0);
     }

   if(CurrentDirection1!=LastDirection1 && FirstTime1==false) // If not the first time and there is a direction change
     {
      LastDirection1=CurrentDirection1; // Set new direction
      return(CurrentDirection1); // 1 for up, 2 for down
     }
   else
     {
      return(0);  // No direction change
     }
  }
//+------------------------------------------------------------------+
// End of Cross                                                      
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// Cross3                                                          
//+------------------------------------------------------------------+

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if a cross happened between 2 lines/data set

/* 

If Output is 0: No cross happened
If Output is 1: Line 1 crossed Line 2 from Bottom
If Output is 2: Line 1 crossed Line 2 from top 

*/

int Crossed3(double line1,double line2)
  {

   static int CurrentDirection1=0;
   static int LastDirection1=0;
   static bool FirstTime1=true;

//----
   if(line1>line2)
      CurrentDirection1=1;  // line1 above line2
   if(line1<line2)
      CurrentDirection1=2;  // line1 below line2    
//----
   if(FirstTime1==true) // Need to check if this is the first time the function is run
     {
      FirstTime1=false; // Change variable to false
      LastDirection1=CurrentDirection1; // Set new direction
      return (0);
     }

   if(CurrentDirection1!=LastDirection1 && FirstTime1==false) // If not the first time and there is a direction change
     {
      LastDirection1=CurrentDirection1; // Set new direction
      return(CurrentDirection1); // 1 for up, 2 for down
     }
   else
     {
      return(0);  // No direction change
     }
  }
//+------------------------------------------------------------------+
// End of Cross                                                      
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Is Loss Limit Breached                                       
//+------------------------------------------------------------------+
bool IsLossLimitBreached(bool LossLimitActivated,double LossLimitPercentage,bool Journaling,int EntrySignalTrigger)
  {

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if our maximum loss threshold is breached

   static bool firstTick=False;
   static double initialCapital=0;
   double profitAndLoss=0;
   double profitAndLossPrint=0;
   bool output=False;

   if(LossLimitActivated==False) return(output);

   if(firstTick==False)
     {
      initialCapital=AccountEquity();
      firstTick=True;
     }

   profitAndLoss=(AccountEquity()/initialCapital)-1;

   if(profitAndLoss<-LossLimitPercentage/100)
     {
      output=True;
      profitAndLossPrint=NormalizeDouble(profitAndLoss,4)*100;
      if(Journaling)if(EntrySignalTrigger!=0) Print("Entry trade triggered but not executed. Loss threshold breached. Current Loss: "+(string)profitAndLossPrint+"%");
     }

   return(output);
  }
//+------------------------------------------------------------------+
//| End of Is Loss Limit Breached                                     
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Is Volatility Limit Breached                                       
//+------------------------------------------------------------------+
bool IsVolLimitBreached(bool VolLimitActivated,double VolMulti,int ATR_Timeframe, int ATR_per)
  {

// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function determines if our maximum volatility threshold is breached

// 2 steps to this function: 
// 1) It checks the price movement between current time and the closing price of the last completed 1min bar (shift 1 of 1min timeframe).
// 2) Return True if this price movement > VolLimitMulti * VolATR

   bool output = False;
   if(VolLimitActivated==False) return(output);
   
   double priceMovement = MathAbs(Bid-iClose(NULL,PERIOD_M1,1)); // Not much difference if we use bid or ask prices here. We can also use iOpen at shift 0 here, it will be similar to using iClose at shift 1.
   double VolATR = iATR(NULL, ATR_Timeframe, ATR_per, 1);
   
   if(priceMovement > VolMulti*VolATR) output = True;

   return(output);
  }
//+------------------------------------------------------------------+
//| End of Is Volatility Limit Breached                                         
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Set Hidden Stop Loss                                     
//+------------------------------------------------------------------+

void SetStopLossHidden(bool Journaling,bool isVolatilitySwitchOn,double fixedSL,double VolATR,double volMultiplier,int K,int OrderNum)
  { // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates hidden stop loss amount and tags it to the appropriate order using an array

   double StopL;

   if(!isVolatilitySwitchOn)
     {
      StopL=fixedSL; // If Volatility Stop Loss not activated. Stop Loss = Fixed Pips Stop Loss
        } else {
      StopL=volMultiplier*VolATR/(K*Point); // Stop Loss in Pips
     }

   for(int x=0; x<ArrayRange(HiddenSLList,0); x++) 
     { // Number of elements in column 1
      if(HiddenSLList[x,0]==0) 
        { // Checks if the element is empty
         HiddenSLList[x,0] = OrderNum;
         HiddenSLList[x,1] = StopL;
         if(Journaling)Print("EA Journaling: Order "+(string)HiddenSLList[x,0]+" assigned with a hidden SL of "+(string)NormalizeDouble(HiddenSLList[x,1],2)+" pips.");
         break;
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Set Hidden Stop Loss                   
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Trigger Hidden Stop Loss                                      
//+------------------------------------------------------------------+
void TriggerStopLossHidden(bool Journaling,int Retry_Interval,int Magic,int Slip,int K) 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

/* This function does two 2 things:
1) Clears appropriate elements of your HiddenSLList if positions has been closed
2) Closes positions based on its hidden stop loss levels
*/

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   double orderSL;
   int doesOrderExist;

// 1) Check the HiddenSLList, match with current list of positions. Make sure the all the positions exists. 
// If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenSLList,0); x++) 
     { // Looping through all order number in list

      doesOrderExist=False;
      orderTicketNumber=(int)HiddenSLList[x,0];

      if(orderTicketNumber!=0) 
        { // Order exists
         for(int y=ordersPos-1; y>=0; y--) 
           { // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
              {
               if(orderTicketNumber==OrderTicket()) 
                 { // Checks order number in list against order number of current positions
                  doesOrderExist=True;
                  break;
                 }
              }
           }

         if(doesOrderExist==False) 
           { // Deletes elements if the order number does not match any current positions
            HiddenSLList[x, 0] = 0;
            HiddenSLList[x, 1] = 0;
           }
        }

     }

// 2) Check each position against its hidden SL and close the position if hidden SL is hit

   for(int z=0; z<ArrayRange(HiddenSLList,0); z++) 
     { // Loops through elements in the list

      orderTicketNumber=(int)HiddenSLList[z,0]; // Records order numner
      orderSL=HiddenSLList[z,1]; // Records SL

      if(OrderSelect(orderTicketNumber,SELECT_BY_TICKET)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {
         bool Closing=false;
         if(OrderType()==OP_BUY && OrderOpenPrice() -(orderSL*K*Point)>=Bid) 
           { // Checks SL condition for closing long orders

            if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Closing=OrderClose(OrderTicket(),OrderLots(),Bid,Slip*K,Blue);
            if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Closing)Print("EA Journaling: Position successfully closed.");

           }
         if(OrderType()==OP_SELL && OrderOpenPrice()+(orderSL*K*Point)<=Ask) 
           { // Checks SL condition for closing short orders

            if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Closing=OrderClose(OrderTicket(),OrderLots(),Ask,Slip*K,Red);
            if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Closing)Print("EA Journaling: Position successfully closed.");

           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Trigger Hidden Stop Loss                                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Set Hidden Take Profit                                     
//+------------------------------------------------------------------+

void SetTakeProfitHidden(bool Journaling,bool isVolatilitySwitchOn,double fixedTP,double VolATR,double volMultiplier,int K,int OrderNum)
  { // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function calculates hidden take profit amount and tags it to the appropriate order using an array

   double TakeP;

   if(!isVolatilitySwitchOn)
     {
      TakeP=fixedTP; // If Volatility Take Profit not activated. Take Profit = Fixed Pips Take Profit
        } else {
      TakeP=volMultiplier*VolATR/(K*Point); // Take Profit in Pips
     }

   for(int x=0; x<ArrayRange(HiddenTPList,0); x++) 
     { // Number of elements in column 1
      if(HiddenTPList[x,0]==0) 
        { // Checks if the element is empty
         HiddenTPList[x,0] = OrderNum;
         HiddenTPList[x,1] = TakeP;
         if(Journaling)Print("EA Journaling: Order "+(string)HiddenTPList[x,0]+" assigned with a hidden TP of "+(string)NormalizeDouble(HiddenTPList[x,1],2)+" pips.");
         break;
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Set Hidden Take Profit                  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Trigger Hidden Take Profit                                        
//+------------------------------------------------------------------+
void TriggerTakeProfitHidden(bool Journaling,int Retry_Interval,int Magic,int Slip,int K) 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

/* This function does two 2 things:
1) Clears appropriate elements of your HiddenTPList if positions has been closed
2) Closes positions based on its hidden take profit levels
*/

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   double orderTP;
   int doesOrderExist;

// 1) Check the HiddenTPList, match with current list of positions. Make sure the all the positions exists. 
// If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenTPList,0); x++) 
     { // Looping through all order number in list

      doesOrderExist=False;
      orderTicketNumber=(int)HiddenTPList[x,0];

      if(orderTicketNumber!=0) 
        { // Order exists
         for(int y=ordersPos-1; y>=0; y--) 
           { // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
              {
               if(orderTicketNumber==OrderTicket()) 
                 { // Checks order number in list against order number of current positions
                  doesOrderExist=True;
                  break;
                 }
              }
           }

         if(doesOrderExist==False) 
           { // Deletes elements if the order number does not match any current positions
            HiddenTPList[x, 0] = 0;
            HiddenTPList[x, 1] = 0;
           }
        }

     }

// 2) Check each position against its hidden TP and close the position if hidden TP is hit

   for(int z=0; z<ArrayRange(HiddenTPList,0); z++) 
     { // Loops through elements in the list

      orderTicketNumber=(int)HiddenTPList[z,0]; // Records order numner
      orderTP=HiddenTPList[z,1]; // Records TP

      if(OrderSelect(orderTicketNumber,SELECT_BY_TICKET)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {
         bool Closing=false;
         if(OrderType()==OP_BUY && OrderOpenPrice()+(orderTP*K*Point)<=Bid) 
           { // Checks TP condition for closing long orders

            if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Closing=OrderClose(OrderTicket(),OrderLots(),Bid,Slip*K,Blue);
            if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Closing)Print("EA Journaling: Position successfully closed.");

           }
         if(OrderType()==OP_SELL && OrderOpenPrice() -(orderTP*K*Point)>=Ask) 
           { // Checks TP condition for closing short orders 

            if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Closing=OrderClose(OrderTicket(),OrderLots(),Ask,Slip*K,Red);
            if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Closing)Print("EA Journaling: Position successfully closed.");

           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Trigger Hidden Take Profit                                       
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Breakeven Stop
//+------------------------------------------------------------------+
void BreakevenStopAll(bool Journaling,int Retry_Interval,double Breakeven_Buffer,int Magic,int K)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function sets breakeven stops for all positions

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      bool Modify=false;
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
        {
         RefreshRates();
         if(OrderType()==OP_BUY && (Bid-OrderOpenPrice())>(Breakeven_Buffer*K*Point))
           {
            if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Modify=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,CLR_NONE);
            if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Modify)Print("EA Journaling: Order successfully modified, breakeven stop updated.");
           }
         if(OrderType()==OP_SELL && (OrderOpenPrice()-Ask)>(Breakeven_Buffer*K*Point))
           {
            if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Modify=OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,CLR_NONE);
            if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Modify)Print("EA Journaling: Order successfully modified, breakeven stop updated.");
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Breakeven Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Update Hidden Breakeven Stops List                                     
//+------------------------------------------------------------------+

void UpdateHiddenBEList(bool Journaling,int Retry_Interval,int Magic) 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function clears the elements of your HiddenBEList if the corresponding positions has been closed

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   bool doesPosExist;

// Check the HiddenBEList, match with current list of positions. Make sure the all the positions exists. 
// If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenBEList,0); x++)
     { // Looping through all order number in list

      doesPosExist=False;
      orderTicketNumber=(int)HiddenBEList[x];

      if(orderTicketNumber!=0)
        { // Order exists
         for(int y=ordersPos-1; y>=0; y--)
           { // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
              {
               if(orderTicketNumber==OrderTicket())
                 { // Checks order number in list against order number of current positions
                  doesPosExist=True;
                  break;
                 }
              }
           }

         if(doesPosExist==False)
           { // Deletes elements if the order number does not match any current positions
            HiddenBEList[x]=0;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Update Hidden Breakeven Stops List                                         
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Set and Trigger Hidden Breakeven Stops                                  
//+------------------------------------------------------------------+

void SetAndTriggerBEHidden(bool Journaling,double Breakeven_Buffer,int Magic,int Slip,int K,int Retry_Interval)
  { // K represents our P multiplier to adjust for broker digits
// Type: Fixed Template 
// Do not edit unless you know what you're doing

/* 
This function scans through the current positions and does 2 things:
1) If the position is in the hidden breakeven list, it closes it if the appropriate conditions are met
2) If the positon is not the hidden breakeven list, it adds it to the list if the appropriate conditions are met
*/

   bool isOrderInBEList=False;
   int orderTicketNumber;

   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      bool Modify=false;
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
        { // Loop through list of current positions
         RefreshRates();
         orderTicketNumber=OrderTicket();
         for(int x=0; x<ArrayRange(HiddenBEList,0); x++)
           { // Loops through hidden BE list
            if(orderTicketNumber==HiddenBEList[x])
              { // Checks if the current position is in the list 
               isOrderInBEList=True;
               break;
              }
           }
         if(isOrderInBEList==True)
           { // If current position is in the list, close it if hidden breakeven stop is breached
            bool Closing=false;
            if(OrderType()==OP_BUY && OrderOpenPrice()>=Bid) 
              { // Checks BE condition for closing long orders    
               if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" using hidden breakeven stop...");
               HandleTradingEnvironment(Journaling,Retry_Interval);
               Closing=OrderClose(OrderTicket(),OrderLots(),Bid,Slip*K,Blue);
               if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
               if(Journaling && Closing)Print("EA Journaling: Position successfully closed due to hidden breakeven stop.");
              }
            if(OrderType()==OP_SELL && OrderOpenPrice()<=Ask) 
              { // Checks BE condition for closing short orders
               if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" using hidden breakeven stop...");
               HandleTradingEnvironment(Journaling,Retry_Interval);
               Closing=OrderClose(OrderTicket(),OrderLots(),Ask,Slip*K,Red);
               if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
               if(Journaling && Closing)Print("EA Journaling: Position successfully closed due to hidden breakeven stop.");
              }
              } else { // If current position is not in the hidden BE list. We check if we need to add this position to the hidden BE list.
            if((OrderType()==OP_BUY && (Bid-OrderOpenPrice())>(Breakeven_Buffer*P*Point)) || (OrderType()==OP_SELL && (OrderOpenPrice()-Ask)>(Breakeven_Buffer*P*Point)))
              {
               for(int y=0; y<ArrayRange(HiddenBEList,0); y++)
                 { // Loop through of elements in column 1
                  if(HiddenBEList[y]==0)
                    { // Checks if the element is empty
                     HiddenBEList[y]= orderTicketNumber;
                     if(Journaling)Print("EA Journaling: Order "+(string)HiddenBEList[y]+" assigned with a hidden breakeven stop.");
                     break;
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Set and Trigger Hidden Breakeven Stops                      
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Trailing Stop
//+------------------------------------------------------------------+

void TrailingStopAll(bool Journaling,double TrailingStopDist,double TrailingStopBuff,int Retry_Interval,int Magic,int K)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function sets trailing stops for all positions

   for(int i=OrdersTotal()-1; i>=0; i--) // Looping through all orders
     {
      bool Modify=false;
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
        {
         RefreshRates();
         if(OrderType()==OP_BUY && (Bid-OrderStopLoss()>(TrailingStopDist+TrailingStopBuff)*K*Point))
           {
            if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Modify=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailingStopDist*K*Point,OrderTakeProfit(),0,CLR_NONE);
            if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Modify)Print("EA Journaling: Order successfully modified, trailing stop changed.");
           }
         if(OrderType()==OP_SELL && ((OrderStopLoss()-Ask>((TrailingStopDist+TrailingStopBuff)*K*Point)) || (OrderStopLoss()==0)))
           {
            if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
            HandleTradingEnvironment(Journaling,Retry_Interval);
            Modify=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStopDist*K*Point,OrderTakeProfit(),0,CLR_NONE);
            if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
            if(Journaling && Modify)Print("EA Journaling: Order successfully modified, trailing stop changed.");
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End Trailing Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Update Hidden Trailing Stops List                                     
//+------------------------------------------------------------------+

void UpdateHiddenTrailingList(bool Journaling,int Retry_Interval,int Magic) 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function clears the elements of your HiddenTrailingList if the corresponding positions has been closed

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   bool doesPosExist;

// Check the HiddenTrailingList, match with current list of positions. Make sure the all the positions exists. 
// If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenTrailingList,0); x++)
     { // Looping through all order number in list

      doesPosExist=False;
      orderTicketNumber=(int)HiddenTrailingList[x,0];

      if(orderTicketNumber!=0)
        { // Order exists
         for(int y=ordersPos-1; y>=0; y--)
           { // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
              {
               if(orderTicketNumber==OrderTicket())
                 { // Checks order number in list against order number of current positions
                  doesPosExist=True;
                  break;
                 }
              }
           }

         if(doesPosExist==False)
           { // Deletes elements if the order number does not match any current positions
            HiddenTrailingList[x,0] = 0;
            HiddenTrailingList[x,1] = 0;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Update Hidden Trailing Stops List                                       
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Set and Trigger Hidden Trailing Stop
//+------------------------------------------------------------------+

void SetAndTriggerHiddenTrailing(bool Journaling,double TrailingStopDist,double TrailingStopBuff,int Slip,int Retry_Interval,int Magic,int K)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function does 2 things. 1) It sets hidden trailing stops for all positions 2) It closes the positions if hidden trailing stops levels are breached

   bool doesHiddenTrailingRecordExist;
   int posTicketNumber;

   for(int i=OrdersTotal()-1; i>=0; i--) 
     { // Looping through all orders

      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {

         doesHiddenTrailingRecordExist=False;
         posTicketNumber=OrderTicket();

         // Step 1: Check if there is any hidden trailing stop records pertaining to this order. If yes, check if we need to close the order.

         for(int x=0; x<ArrayRange(HiddenTrailingList,0); x++) 
           { // Looping through all order number in list 

            if(posTicketNumber==HiddenTrailingList[x,0]) 
              { // If condition holds, it means the position have a hidden trailing stop level attached to it

               doesHiddenTrailingRecordExist=True;
               bool Closing=false;
               RefreshRates();

               if(OrderType()==OP_BUY && HiddenTrailingList[x,1]>=Bid) 
                 {

                  if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" using hidden trailing stop...");
                  HandleTradingEnvironment(Journaling,Retry_Interval);
                  Closing=OrderClose(OrderTicket(),OrderLots(),Bid,Slip*K,Blue);
                  if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
                  if(Journaling && Closing)Print("EA Journaling: Position successfully closed due to hidden trailing stop.");

                    } else if(OrderType()==OP_SELL && HiddenTrailingList[x,1]<=Ask) {

                  if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" using hidden trailing stop...");
                  HandleTradingEnvironment(Journaling,Retry_Interval);
                  Closing=OrderClose(OrderTicket(),OrderLots(),Ask,Slip*K,Red);
                  if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
                  if(Journaling && Closing)Print("EA Journaling: Position successfully closed due to hidden trailing stop.");

                    }  else {

                  // Step 2: If there are hidden trailing stop records and the position was not closed in Step 1. We update the hidden trailing stop record.

                  if(OrderType()==OP_BUY && (Bid-HiddenTrailingList[x,1]>(TrailingStopDist+TrailingStopBuff)*K*Point)) 
                    {
                     HiddenTrailingList[x,1]=Bid-TrailingStopDist*K*Point; // Assigns new hidden trailing stop level
                     if(Journaling)Print("EA Journaling: Order "+(string)posTicketNumber+" successfully modified, hidden trailing stop updated to "+(string)NormalizeDouble(HiddenTrailingList[x,1],Digits)+".");
                    }
                  if(OrderType()==OP_SELL && (HiddenTrailingList[x,1]-Ask>((TrailingStopDist+TrailingStopBuff)*K*Point))) 
                    {
                     HiddenTrailingList[x,1]=Ask+TrailingStopDist*K*Point; // Assigns new hidden trailing stop level
                     if(Journaling)Print("EA Journaling: Order "+(string)posTicketNumber+" successfully modified, hidden trailing stop updated "+(string)NormalizeDouble(HiddenTrailingList[x,1],Digits)+".");
                    }
                 }
               break;
              }
           }

         // Step 3: If there are no hidden trailing stop records, add new record.

         if(doesHiddenTrailingRecordExist==False) 
           {

            for(int y=0; y<ArrayRange(HiddenTrailingList,0); y++) 
              { // Looping through list 

               if(HiddenTrailingList[y,0]==0) 
                 { // Slot is empty

                  RefreshRates();
                  HiddenTrailingList[y,0]=posTicketNumber; // Assigns Order Number
                  if(OrderType()==OP_BUY) 
                    {
                     HiddenTrailingList[y,1]=MathMax(Bid,OrderOpenPrice())-TrailingStopDist*K*Point; // Hidden trailing stop level = Higher of Bid or OrderOpenPrice - Trailing Stop Distance
                     if(Journaling)Print("EA Journaling: Order "+(string)posTicketNumber+" successfully modified, hidden trailing stop added. Trailing Stop = "+(string)NormalizeDouble(HiddenTrailingList[y,1],Digits)+".");
                    }
                  if(OrderType()==OP_SELL) 
                    {
                     HiddenTrailingList[y,1]=MathMin(Ask,OrderOpenPrice())+TrailingStopDist*K*Point; // Hidden trailing stop level = Lower of Ask or OrderOpenPrice + Trailing Stop Distance
                     if(Journaling)Print("EA Journaling: Order "+(string)posTicketNumber+" successfully modified, hidden trailing stop added. Trailing Stop = "+(string)NormalizeDouble(HiddenTrailingList[y,1],Digits)+".");
                    }
                  break;
                 }
              }
           }

        }
     }
  }
//+------------------------------------------------------------------+
//| End of Set and Trigger Hidden Trailing Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Update Volatility Trailing Stops List                                     
//+------------------------------------------------------------------+

void UpdateVolTrailingList(bool Journaling,int Retry_Interval,int Magic) 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function clears the elements of your VolTrailingList if the corresponding positions has been closed

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   bool doesPosExist;

// Check the VolTrailingList, match with current list of positions. Make sure the all the positions exists. 
// If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(VolTrailingList,0); x++)
     { // Looping through all order number in list

      doesPosExist=False;
      orderTicketNumber=(int)VolTrailingList[x,0];

      if(orderTicketNumber!=0)
        { // Order exists
         for(int y=ordersPos-1; y>=0; y--)
           { // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
              {
               if(orderTicketNumber==OrderTicket())
                 { // Checks order number in list against order number of current positions
                  doesPosExist=True;
                  break;
                 }
              }
           }

         if(doesPosExist==False)
           { // Deletes elements if the order number does not match any current positions
            VolTrailingList[x,0] = 0;
            VolTrailingList[x,1] = 0;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Update Volatility Trailing Stops List                                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Set Volatility Trailing Stop
//+------------------------------------------------------------------+

void SetVolTrailingStop(bool Journaling,int Retry_Interval,double VolATR,double VolTrailingDistMulti,int Magic,int K,int OrderNum)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function adds new volatility trailing stop level using OrderModify()

   double VolTrailingStopDist;
   bool Modify=False;
   bool IsVolTrailingStopAdded=False;
   
   VolTrailingStopDist=VolTrailingDistMulti*VolATR/(K*Point); // Volatility trailing stop amount in Pips

   if(OrderSelect(OrderNum,SELECT_BY_TICKET)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
     {
      RefreshRates();
      if(OrderType()==OP_BUY)
        {
         if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
         HandleTradingEnvironment(Journaling,Retry_Interval);
         Modify=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-VolTrailingStopDist*K*Point,OrderTakeProfit(),0,CLR_NONE);
         IsVolTrailingStopAdded=True;   
         if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
         if(Journaling && Modify)Print("EA Journaling: Order successfully modified, volatility trailing stop changed.");
        }
      if(OrderType()==OP_SELL)
        {
         if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
         HandleTradingEnvironment(Journaling,Retry_Interval);
         Modify=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+VolTrailingStopDist*K*Point,OrderTakeProfit(),0,CLR_NONE);
         IsVolTrailingStopAdded=True;
         if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
         if(Journaling && Modify)Print("EA Journaling: Order successfully modified, volatility trailing stop changed.");
        } 
     
      // Records volatility measure (ATR value) for future use
      if(IsVolTrailingStopAdded==True) 
         {
         for(int x=0; x<ArrayRange(VolTrailingList,0); x++) // Loop through elements in VolTrailingList
           { 
            if(VolTrailingList[x,0]==0)  // Checks if the element is empty
              { 
               VolTrailingList[x,0]=OrderNum; // Add order number
               VolTrailingList[x,1]=VolATR/(K*Point); // Add volatility measure aka 1 unit of ATR
               break;
              }
           }
         }
     }     
  }
//+------------------------------------------------------------------+
//| End of Set Volatility Trailing Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Review Hidden Volatility Trailing Stop
//+------------------------------------------------------------------+

void ReviewVolTrailingStop(bool Journaling, double VolTrailingDistMulti, double VolTrailingBuffMulti, int Retry_Interval, int Magic, int K)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function updates volatility trailing stops levels for all positions (using OrderModify) if appropriate conditions are met

   bool doesVolTrailingRecordExist;
   int posTicketNumber;

   for(int i=OrdersTotal()-1; i>=0; i--) 
     { // Looping through all orders

      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {
         doesVolTrailingRecordExist = False;
         posTicketNumber=OrderTicket();

         for(int x=0; x<ArrayRange(VolTrailingList,0); x++) 
           { // Looping through all order number in list 

            if(posTicketNumber==VolTrailingList[x,0]) 
              { // If condition holds, it means the position have a volatility trailing stop level attached to it

               doesVolTrailingRecordExist = True; 
               bool Modify=false;
               RefreshRates();

               // We update the volatility trailing stop record using OrderModify.
               if(OrderType()==OP_BUY && (Bid-OrderStopLoss()>(VolTrailingDistMulti*VolTrailingList[x,1]+VolTrailingBuffMulti*VolTrailingList[x,1])*K*Point))
                 {
                  if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
                  HandleTradingEnvironment(Journaling,Retry_Interval);
                  Modify=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-VolTrailingDistMulti*VolTrailingList[x,1]*K*Point,OrderTakeProfit(),0,CLR_NONE);
                  if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
                  if(Journaling && Modify)Print("EA Journaling: Order successfully modified, volatility trailing stop changed.");
                 }
               if(OrderType()==OP_SELL && ((OrderStopLoss()-Ask>((VolTrailingDistMulti*VolTrailingList[x,1]+VolTrailingBuffMulti*VolTrailingList[x,1])*K*Point)) || (OrderStopLoss()==0)))
                 {
                  if(Journaling)Print("EA Journaling: Trying to modify order "+(string)OrderTicket()+" ...");
                  HandleTradingEnvironment(Journaling,Retry_Interval);
                  Modify=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+VolTrailingDistMulti*VolTrailingList[x,1]*K*Point,OrderTakeProfit(),0,CLR_NONE);
                  if(Journaling && !Modify)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
                  if(Journaling && Modify)Print("EA Journaling: Order successfully modified, volatility trailing stop changed.");
                 }
               break;
              }
           }
        // If order does not have a record attached to it. Alert the trader.
        if(!doesVolTrailingRecordExist && Journaling) Print("EA Journaling: Error. Order "+(string)posTicketNumber+" has no volatility trailing stop attached to it.");
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Review Volatility Trailing Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Update Hidden Volatility Trailing Stops List                                     
//+------------------------------------------------------------------+

void UpdateHiddenVolTrailingList(bool Journaling,int Retry_Interval,int Magic) 
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function clears the elements of your HiddenVolTrailingList if the corresponding positions has been closed

   int ordersPos=OrdersTotal();
   int orderTicketNumber;
   bool doesPosExist;

// Check the HiddenVolTrailingList, match with current list of positions. Make sure the all the positions exists. 
// If it doesn't, it means there are positions that have been closed

   for(int x=0; x<ArrayRange(HiddenVolTrailingList,0); x++)
     { // Looping through all order number in list

      doesPosExist=False;
      orderTicketNumber=(int)HiddenVolTrailingList[x,0];

      if(orderTicketNumber!=0)
        { // Order exists
         for(int y=ordersPos-1; y>=0; y--)
           { // Looping through all current open positions
            if(OrderSelect(y,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic)
              {
               if(orderTicketNumber==OrderTicket())
                 { // Checks order number in list against order number of current positions
                  doesPosExist=True;
                  break;
                 }
              }
           }

         if(doesPosExist==False)
           { // Deletes elements if the order number does not match any current positions
            HiddenVolTrailingList[x,0] = 0;
            HiddenVolTrailingList[x,1] = 0;
            HiddenVolTrailingList[x,2] = 0;
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Update Hidden Volatility Trailing Stops List                                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Set Hidden Volatility Trailing Stop
//+------------------------------------------------------------------+

void SetHiddenVolTrailing(bool Journaling,double VolATR,double VolTrailingDistMultiplierHidden,int Magic,int K,int OrderNum)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function adds new hidden volatility trailing stop record 

   double VolTrailingStopLevel = 0;
   double VolTrailingStopDist;

   VolTrailingStopDist=VolTrailingDistMultiplierHidden*VolATR/(K*Point); // Volatility trailing stop amount in Pips

   if(OrderSelect(OrderNum,SELECT_BY_TICKET)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
     {
      RefreshRates();
      if(OrderType()==OP_BUY)  VolTrailingStopLevel = MathMax(Bid, OrderOpenPrice()) - VolTrailingStopDist*K*Point; // Volatility trailing stop level of buy trades
      if(OrderType()==OP_SELL) VolTrailingStopLevel = MathMin(Ask, OrderOpenPrice()) + VolTrailingStopDist*K*Point; // Volatility trailing stop level of sell trades
     
     }

   for(int x=0; x<ArrayRange(HiddenVolTrailingList,0); x++) // Loop through elements in HiddenVolTrailingList
     { 
      if(HiddenVolTrailingList[x,0]==0)  // Checks if the element is empty
        { 
         HiddenVolTrailingList[x,0] = OrderNum; // Add order number
         HiddenVolTrailingList[x,1] = VolTrailingStopLevel; // Add volatility trailing stop level 
         HiddenVolTrailingList[x,2] = VolATR/(K*Point); // Add volatility measure aka 1 unit of ATR
         if(Journaling)Print("EA Journaling: Order "+(string)HiddenVolTrailingList[x,0]+" assigned with a hidden volatility trailing stop level of "+(string)NormalizeDouble(HiddenVolTrailingList[x,1],Digits)+".");
         break;
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Set Hidden Volatility Trailing Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Trigger and Review Hidden Volatility Trailing Stop
//+------------------------------------------------------------------+

void TriggerAndReviewHiddenVolTrailing(bool Journaling, double VolTrailingDistMultiplierHidden, double VolTrailingBuffMultiplierHidden, int Slip, int Retry_Interval, int Magic, int K)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function does 2 things. 1) It closes the positions if hidden volatility trailing stops levels are breached. 2) It updates hidden volatility trailing stops for all positions if appropriate conditions are met

   bool doesHiddenVolTrailingRecordExist;
   int posTicketNumber;

   for(int i=OrdersTotal()-1; i>=0; i--) 
     { // Looping through all orders

      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) 
        {
         doesHiddenVolTrailingRecordExist = False;
         posTicketNumber=OrderTicket();

         // 1) Check if we need to close the order.

         for(int x=0; x<ArrayRange(HiddenVolTrailingList,0); x++) 
           { // Looping through all order number in list 

            if(posTicketNumber==HiddenVolTrailingList[x,0]) 
              { // If condition holds, it means the position have a hidden volatility trailing stop level attached to it

               doesHiddenVolTrailingRecordExist = True; 
               bool Closing=false;
               RefreshRates();

               if(OrderType()==OP_BUY && HiddenVolTrailingList[x,1]>=Bid) 
                 {

                  if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" using hidden volatility trailing stop...");
                  HandleTradingEnvironment(Journaling,Retry_Interval);
                  Closing=OrderClose(OrderTicket(),OrderLots(),Bid,Slip*K,Blue);
                  if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
                  if(Journaling && Closing)Print("EA Journaling: Position successfully closed due to hidden volatility trailing stop.");

                    } else if (OrderType()==OP_SELL && HiddenVolTrailingList[x,1]<=Ask) {

                  if(Journaling)Print("EA Journaling: Trying to close position "+(string)OrderTicket()+" using hidden volatility trailing stop...");
                  HandleTradingEnvironment(Journaling,Retry_Interval);
                  Closing=OrderClose(OrderTicket(),OrderLots(),Ask,Slip*K,Red);
                  if(Journaling && !Closing)Print("EA Journaling: Unexpected Error has happened. Error Description: "+GetErrorDescription(GetLastError()));
                  if(Journaling && Closing)Print("EA Journaling: Position successfully closed due to hidden volatility trailing stop.");

                    }  else {

                  // 2) If orders was not closed in 1), we update the hidden volatility trailing stop record.

                  if(OrderType()==OP_BUY && (Bid-HiddenVolTrailingList[x,1]>(VolTrailingDistMultiplierHidden*HiddenVolTrailingList[x,2]+VolTrailingBuffMultiplierHidden*HiddenVolTrailingList[x,2])*K*Point)) 
                    {
                     HiddenVolTrailingList[x,1]=Bid-VolTrailingDistMultiplierHidden*HiddenVolTrailingList[x,2]*K*Point; // Assigns new hidden trailing stop level
                     if(Journaling)Print("EA Journaling: Order "+(string)posTicketNumber+" successfully modified, hidden volatility trailing stop updated to "+(string)NormalizeDouble(HiddenVolTrailingList[x,1],Digits)+".");
                    }
                  if(OrderType()==OP_SELL && (HiddenVolTrailingList[x,1]-Ask>(VolTrailingDistMultiplierHidden*HiddenVolTrailingList[x,2]+VolTrailingBuffMultiplierHidden*HiddenVolTrailingList[x,2])*K*Point))
                    {
                     HiddenVolTrailingList[x,1]=Ask+VolTrailingDistMultiplierHidden*HiddenVolTrailingList[x,2]*K*Point; // Assigns new hidden trailing stop level
                     if(Journaling)Print("EA Journaling: Order "+(string)posTicketNumber+" successfully modified, hidden volatility trailing stop updated "+(string)NormalizeDouble(HiddenVolTrailingList[x,1],Digits)+".");
                    }
                 }
               break;
              }
           }
        // If order does not have a record attached to it. Alert the trader.
        if(!doesHiddenVolTrailingRecordExist && Journaling) Print("EA Journaling: Error. Order "+(string)posTicketNumber+" has no hidden volatility trailing stop attached to it.");
        }
     }
  }
//+------------------------------------------------------------------+
//| End of Trigger and Review Hidden Volatility Trailing Stop
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| HANDLE TRADING ENVIRONMENT                                       
//+------------------------------------------------------------------+
void HandleTradingEnvironment(bool Journaling,int Retry_Interval)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing 

// This function checks for errors

   if(IsTradeAllowed()==true)return;
   if(!IsConnected())
     {
      if(Journaling)Print("EA Journaling: Terminal is not connected to server...");
      return;
     }
   if(!IsTradeAllowed() && Journaling)Print("EA Journaling: Trade is not alowed for some reason...");
   if(IsConnected() && !IsTradeAllowed())
     {
      while(IsTradeContextBusy()==true)
        {
         if(Journaling)Print("EA Journaling: Trading context is busy... Will wait a bit...");
         Sleep(Retry_Interval);
        }
     }
   RefreshRates();
  }
//+------------------------------------------------------------------+
//| End of HANDLE TRADING ENVIRONMENT                                
//+------------------------------------------------------------------+  
//+------------------------------------------------------------------+
//| ERROR DESCRIPTION                                                
//+------------------------------------------------------------------+
string GetErrorDescription(int error)
  {
// Type: Fixed Template 
// Do not edit unless you know what you're doing

// This function returns the exact error

   string ErrorDescription="";
//---
   switch(error)
     {
      case 0:     ErrorDescription = "NO Error. Everything should be good.";                                    break;
      case 1:     ErrorDescription = "No error returned, but the result is unknown";                            break;
      case 2:     ErrorDescription = "Common error";                                                            break;
      case 3:     ErrorDescription = "Invalid trade parameters";                                                break;
      case 4:     ErrorDescription = "Trade server is busy";                                                    break;
      case 5:     ErrorDescription = "Old version of the client terminal";                                      break;
      case 6:     ErrorDescription = "No connection with trade server";                                         break;
      case 7:     ErrorDescription = "Not enough rights";                                                       break;
      case 8:     ErrorDescription = "Too frequent requests";                                                   break;
      case 9:     ErrorDescription = "Malfunctional trade operation";                                           break;
      case 64:    ErrorDescription = "Account disabled";                                                        break;
      case 65:    ErrorDescription = "Invalid account";                                                         break;
      case 128:   ErrorDescription = "Trade timeout";                                                           break;
      case 129:   ErrorDescription = "Invalid price";                                                           break;
      case 130:   ErrorDescription = "Invalid stops";                                                           break;
      case 131:   ErrorDescription = "Invalid trade volume";                                                    break;
      case 132:   ErrorDescription = "Market is closed";                                                        break;
      case 133:   ErrorDescription = "Trade is disabled";                                                       break;
      case 134:   ErrorDescription = "Not enough money";                                                        break;
      case 135:   ErrorDescription = "Price changed";                                                           break;
      case 136:   ErrorDescription = "Off quotes";                                                              break;
      case 137:   ErrorDescription = "Broker is busy";                                                          break;
      case 138:   ErrorDescription = "Requote";                                                                 break;
      case 139:   ErrorDescription = "Order is locked";                                                         break;
      case 140:   ErrorDescription = "Long positions only allowed";                                             break;
      case 141:   ErrorDescription = "Too many requests";                                                       break;
      case 145:   ErrorDescription = "Modification denied because order too close to market";                   break;
      case 146:   ErrorDescription = "Trade context is busy";                                                   break;
      case 147:   ErrorDescription = "Expirations are denied by broker";                                        break;
      case 148:   ErrorDescription = "Too many open and pending orders (more than allowed)";                    break;
      case 4000:  ErrorDescription = "No error";                                                                break;
      case 4001:  ErrorDescription = "Wrong function pointer";                                                  break;
      case 4002:  ErrorDescription = "Array index is out of range";                                             break;
      case 4003:  ErrorDescription = "No memory for function call stack";                                       break;
      case 4004:  ErrorDescription = "Recursive stack overflow";                                                break;
      case 4005:  ErrorDescription = "Not enough stack for parameter";                                          break;
      case 4006:  ErrorDescription = "No memory for parameter string";                                          break;
      case 4007:  ErrorDescription = "No memory for temp string";                                               break;
      case 4008:  ErrorDescription = "Not initialized string";                                                  break;
      case 4009:  ErrorDescription = "Not initialized string in array";                                         break;
      case 4010:  ErrorDescription = "No memory for array string";                                              break;
      case 4011:  ErrorDescription = "Too long string";                                                         break;
      case 4012:  ErrorDescription = "Remainder from zero divide";                                              break;
      case 4013:  ErrorDescription = "Zero divide";                                                             break;
      case 4014:  ErrorDescription = "Unknown command";                                                         break;
      case 4015:  ErrorDescription = "Wrong jump (never generated error)";                                      break;
      case 4016:  ErrorDescription = "Not initialized array";                                                   break;
      case 4017:  ErrorDescription = "DLL calls are not allowed";                                               break;
      case 4018:  ErrorDescription = "Cannot load library";                                                     break;
      case 4019:  ErrorDescription = "Cannot call function";                                                    break;
      case 4020:  ErrorDescription = "Expert function calls are not allowed";                                   break;
      case 4021:  ErrorDescription = "Not enough memory for temp string returned from function";                break;
      case 4022:  ErrorDescription = "System is busy (never generated error)";                                  break;
      case 4050:  ErrorDescription = "Invalid function parameters count";                                       break;
      case 4051:  ErrorDescription = "Invalid function parameter value";                                        break;
      case 4052:  ErrorDescription = "String function internal error";                                          break;
      case 4053:  ErrorDescription = "Some array error";                                                        break;
      case 4054:  ErrorDescription = "Incorrect series array using";                                            break;
      case 4055:  ErrorDescription = "Custom indicator error";                                                  break;
      case 4056:  ErrorDescription = "Arrays are incompatible";                                                 break;
      case 4057:  ErrorDescription = "Global variables processing error";                                       break;
      case 4058:  ErrorDescription = "Global variable not found";                                               break;
      case 4059:  ErrorDescription = "Function is not allowed in testing mode";                                 break;
      case 4060:  ErrorDescription = "Function is not confirmed";                                               break;
      case 4061:  ErrorDescription = "Send mail error";                                                         break;
      case 4062:  ErrorDescription = "String parameter expected";                                               break;
      case 4063:  ErrorDescription = "Integer parameter expected";                                              break;
      case 4064:  ErrorDescription = "Double parameter expected";                                               break;
      case 4065:  ErrorDescription = "Array as parameter expected";                                             break;
      case 4066:  ErrorDescription = "Requested history data in updating state";                                break;
      case 4067:  ErrorDescription = "Some error in trading function";                                          break;
      case 4099:  ErrorDescription = "End of file";                                                             break;
      case 4100:  ErrorDescription = "Some file error";                                                         break;
      case 4101:  ErrorDescription = "Wrong file name";                                                         break;
      case 4102:  ErrorDescription = "Too many opened files";                                                   break;
      case 4103:  ErrorDescription = "Cannot open file";                                                        break;
      case 4104:  ErrorDescription = "Incompatible access to a file";                                           break;
      case 4105:  ErrorDescription = "No order selected";                                                       break;
      case 4106:  ErrorDescription = "Unknown symbol";                                                          break;
      case 4107:  ErrorDescription = "Invalid price";                                                           break;
      case 4108:  ErrorDescription = "Invalid ticket";                                                          break;
      case 4109:  ErrorDescription = "EA is not allowed to trade is not allowed. ";                             break;
      case 4110:  ErrorDescription = "Longs are not allowed. Check the expert properties";                      break;
      case 4111:  ErrorDescription = "Shorts are not allowed. Check the expert properties";                     break;
      case 4200:  ErrorDescription = "Object exists already";                                                   break;
      case 4201:  ErrorDescription = "Unknown object property";                                                 break;
      case 4202:  ErrorDescription = "Object does not exist";                                                   break;
      case 4203:  ErrorDescription = "Unknown object type";                                                     break;
      case 4204:  ErrorDescription = "No object name";                                                          break;
      case 4205:  ErrorDescription = "Object coordinates error";                                                break;
      case 4206:  ErrorDescription = "No specified subwindow";                                                  break;
      case 4207:  ErrorDescription = "Some error in object function";                                           break;
      default:    ErrorDescription = "No error or error is unknown";
     }
   return(ErrorDescription);
  }
//+------------------------------------------------------------------+
//| End of ERROR DESCRIPTION                                         
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
// FUNCTION Euclidiean Metric (Probability)                         
//+------------------------------------------------------------------+
// This function returns probabilities to win the trade

/* 
Output probability value from 1 to 0
Inputs: 
&X_Data_Base[][v_dim_x]  - base_buy/sell is the content of the database with the vectors
&Vector[v_dim_x]         - vector is the current vectors obtained in the trading system
 num_v                   - numbers_of_vectors_buy / sell total numbers of vectors in the data base file *.dat
*/


double Euclidean_Metric(double &X_Data_Base[][v_dim_x], double &Vector[v_dim_x],int num_v)
{
   int i=0,i1=0,i3,i2,i4;
   double Metric[1];
   double t,sum;
   ArrayResize(Metric,num_v);
   ArrayInitialize(Metric,0.0);
   
   for(i=0;i<num_v;i++)
   {
      for(i1=0;i1<v_dim_x-1;i1++)Metric[i]+=MathPow(X_Data_Base[i][i1]-Vector[i1],2); //calculate squared distances between current vectors and the one in the file and sum the powers!
      Metric[i]=MathSqrt(Metric[i]);                                                  //get the square root from the obtained value
   }
   
   //sort by ASCEND Metric
   for(i3=0;i3<num_v-1;i3++)
      for(i2=i3+1;i2<num_v;i2++)     
         if(Metric[i3]>Metric[i2])
         {
            t=Metric[i3];
            Metric[i3]=Metric[i2];
            Metric[i2]=t;
            for(i4=0;i4<v_dim_x;i4++)
            {
               t=X_Data_Base[i3][i4];
               X_Data_Base[i3][i4]=X_Data_Base[i2][i4];
               X_Data_Base[i2][i4]=t;
            }
         }
   sum=0;
   for(i=0;i<Num_neighbour;i++)
   {
      //IF ERROR IS FOUND HERE: Train the robot by running Strategy Tester with parameter Base = True!
      sum+=X_Data_Base[i][5];//суммируем 0 и 1 ближайших соседей чтобы вывести итоговую вероятность выигрыша в этой сделке
      //Print(X_Data_Base[i][5]);
   }
   return(sum/Num_neighbour);
}
//+------------------------------------------------------------------+
// END of FUNCTION Euclidean Metric                                                    
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Dashboard - Comment Version                                    
//+------------------------------------------------------------------+
void ShowDashboard(string Descr0, int magic,
                   string Descr1, int Param1,
                   string Descr2, double Param2,
                   string Descr3, int Param3,
                   string Descr4, double Param4,
                   string Descr5, int Param5,
                   string Descr6, double Param6
                     ) 
  {
// Purpose: This function creates a dashboard showing information on your EA using comments function
// Type: Customisable 
// Modify this function to suit your trading robot
//----

string new_line = "\n"; // "\n" or "\n\n" will move the comment to new line
string space = ": ";    // generate space
string underscore = "________________________________";

Comment(
        new_line 
      + Descr0 + space + IntegerToString(magic)
      + new_line
      + underscore  
      + new_line 
      + new_line
      + Descr1 + space + IntegerToString(Param1)
      + new_line
      + Descr2 + space + DoubleToString(Param2, 1)
      + new_line        
      + underscore  
      + new_line 
      + new_line
      + Descr3 + space + IntegerToString(Param3)
      + new_line
      + Descr4 + space + DoubleToString(Param4, 1)
      + new_line        
      + underscore  
      + new_line 
      + new_line
      + Descr5 + space + IntegerToString(Param5)
      + new_line
      + Descr6 + space + DoubleToString(Param6, 1)
      + new_line        
      + underscore  
      + "");
      
      
  }

//+------------------------------------------------------------------+
//| End of Dashboard - Comment Version                                     
//+------------------------------------------------------------------+   
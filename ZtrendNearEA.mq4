//+------------------------------------------------------------------+
//|                                                 ZtrendNearEA.mq4 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
 
  double new_point =  0.0001;
  int OnInit()
  {
   
   if(Symbol() == "XAGUSD"){
      new_point = 0.01;
   }
   if(Symbol() == "XAUUSD"){
      new_point = 0.1;
  
   }
   if(Symbol() == "GBPJPY"){
      new_point = 0.01;
   }
   if(Symbol() == "USDJPY"){
      new_point = 0.01;
   }
   
   return(INIT_SUCCEEDED);
  }

  
  bool is_allow_order = true;
  int order_nums = 0;
  int opentime;
  void OnTick()
  {
  
   
    if(order_nums > 0 && opentime != Time[0]){ //如果之前下过单并且开盘时间更新，则是新的K线
       order_nums = 0;
       is_allow_order = true;
    }
    if(opentime == Time[0] && order_nums > 0){
       is_allow_order = false;
    }
    
    double order_lots = get_lots();
    
    int sun = 20;
    int ying = 25;
     
    opentime =  Time[0];
    
    
    //获取趋势线的值
    
    double line_price_high_1 =  iCustom(Symbol(),Period(), "ZTrend_NearLine",1, 0, 0);

    double line_price_low_1 =  iCustom(Symbol(),Period(), "ZTrend_NearLine",2, 0, 0);
    
    //核心算法：
    // 1 C点低。
    // 2 CE时间长  (CE > AC)
    // 3 DE距离近
    
    datetime time_cur = TimeCurrent();
    datetime high_time1 = ObjectGet("trend_high",OBJPROP_TIME1);
    datetime high_time2 = ObjectGet("trend_high",OBJPROP_TIME2);
   
    
    double price_cur = Time[0];
    double high_price1 = ObjectGet("trend_high",OBJPROP_PRICE1);
    double high_price2 = ObjectGet("trend_high",OBJPROP_PRICE2);
    
    // 获取射线两个点的索引
    int high_shift1 = ObjectGetShiftByValue("trend_high",high_price1);
    int high_shift2 = ObjectGetShiftByValue("trend_high",high_price2);
    
    //或者两个索引之间的最低点
    double price_high_b  = iLowest(Symbol(),Period(),high_shift1-high_shift2,high_shift2);
    
    double price_ab = high_price1 - price_high_b;
    double price_bc = high_price2 - price_high_b;
     
    int time_ce = time_cur - high_time2;
    int time_ac = high_time2 - high_time1;
    
    
    
    //如果时间 CE > AC 并且 价格 AB > BC * 2 并且DE距离近，看突破
    
    if(is_allow_order){
       if(time_ce > time_ac){
       
          if(price_ab > (price_bc*2) ){
              
              if(Close[2] > line_price_high_1 && Close[1] <= line_price_high_1){
                buy(order_lots,Ask-new_point*sun,Ask+new_point*ying,Symbol()+"buy_"+Hour(),0);
                order_nums = order_nums + 1; 
              }
              
          }
         
       }
    }
   
    
    Print("t_cur:"+time_cur);
   
    
    if(Close[2] > line_price_high_1 && Close[1] <= line_price_high_1 ){
       //buy(order_lots,Ask-new_point*sun,Ask+new_point*ying,Symbol()+"buy_"+Hour(),0);
      // order_nums = order_nums + 1; 
    }
    
    if(Close[2] < line_price_low_1 && Close[1] >= line_price_low_1 ){
        //sell(order_lots,Ask+new_point*sun,Bid-new_point*ying,Symbol()+"sell_"+Hour(),0);
       // order_nums = order_nums + 1; 
    }
    
  }
  
  
  
  int close_all(){
    int a = 0;
    Print("总数："+OrdersTotal());
    
     for(int j=0;j< OrdersTotal();j++){
       Print(j);
     }
    for(int j=OrdersTotal();j>= 0;j--){
      if(OrderSelect(j,SELECT_BY_POS,MODE_TRADES)){
         if((OrderType() == OP_BUY) ){  //如果存在，则不开单
           bool result = OrderClose(OrderTicket(),OrderLots(),Bid,2,White);
           if(result == false){
              Print(" "+GetLastError());
           }
         }
         if((OrderType() == OP_SELL) ){  //如果存在，则不开单
           bool result2 = OrderClose(OrderTicket(),OrderLots(),Ask,2,White);
            if(result2 == false){
              Print(" "+GetLastError());
           }
         }   
      }
      Print(j);
    }
    return 0;
 }
  
     
 //买入函数
 int buy(double lots,double sun,double ying,string comment,int magic){
    int is_kaidan = 1;
    for(int i=0;i< OrdersTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
        if((OrderComment() == comment) && (OrderMagicNumber() == magic) ){ //如果存在，则不开单
          is_kaidan = 0;
        }
      }
    }
    
    if(is_kaidan == 1){ //如果开单
    
      int ticket = OrderSend(Symbol(),OP_BUY,lots,Ask,30,sun,ying,comment,magic,Green);
      return ticket;
    }else{
      return 0;
    }
    
 }
 
  //卖出函数
 int sell(double lots,double sun,double ying,string comment,int magic){
    int is_kaidan = 1;
    for(int i=0;i< OrdersTotal();i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
        if((OrderComment() == comment) && (OrderMagicNumber() == magic) ){ //如果存在，则不开单
          is_kaidan = 0;
        }
      }
    }
    
    if(is_kaidan == 1){ //如果开单
    
      int ticket = OrderSend(Symbol(),OP_SELL,lots,Bid,30,sun,ying,comment,magic,Red);
      return ticket;
    }else{
      return 0;
    }
    
 }
 
  //获取下单量
 double get_lots(){
   double balace = AccountBalance();
   double order_lots = AccountBalance()/10000.0;
   order_lots = NormalizeDouble(order_lots,1);
   order_lots = 0.5;
   return order_lots;
 }




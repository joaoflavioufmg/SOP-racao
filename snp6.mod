# Genral Supply Network Planning Model for Steel Industry
# Autor: JoÃ£oo FlÃ¡vio de Freitas Almeida - <joao.flavio@dep.ufmg.br>
# Professor EP - UFMG

/* The SUPPLY NETWORK PLANNING is a network flow problem that determines
   the best production and transportation strategy of throw a supply chain network.
   The goal is to buy row materials from suppliers, produce and deliver finished 
   products to customers located in several places in a geographical area with 
   the minimum cost in a planning horizon.*/

# glpsol -m snp5.mod -d snp5.dat --cuts --mipgap 0.01

#Sets
# set    name    alias     domain    , atrib , atrib , ... ,     atrib;
# optional atribs:
# dimen n
# within
# :=
# default expression

set V            'suppliers';                                    #vendors (suppliers)
set F            'plant' ;                                        #plants (facilities)
# set DC          'distr centers' ;                                #DCs (distribution centers)
set C            'customers' ;                                    #customers
set L            'locations' := V union F union C;    #locations
set M            'modals';                                        #modals of transport
set X            'raw material' ;                                #components
set Y            'finished products' ;                            #finished products
set P            'products'  := X union Y;                        #products
set R            'machines of plant'     {F};                    #resources of plant F
set L_VF        'link suplier plant'    := {V,F}    within {V,F};          # link supplier plant
# set L_FR        'link plant machines'   {f in F,Y}  within {F,R[f]} union {R[f], R[f]} union {R[f], F};  # link plant machines
set L_FC       'link plant Customers'  := {F,C}    within {F,C} ;         # link plant Customers
#set L_DCC       'link DCs customers'                 within {DC,C};         # link DCs customers
set LK          'link connection'  := L_VF union L_FC ; # transportation links

param T            'time periods'  :=    12;        #buckets
# param S         'scenarios'     :=  3;      #scenario for demand forecast: [1] pessimist [2] mostLikely [3] optimistic

# Parameters
# param    name    alias    domain    , atrib, atrib, ... , atrib ;
# optional atribs:
# integer    - only integer numeric values
# binary        - either 0 or 1
# symbolic    - any numeric and symbolic values
# relation expression <, <=, =, ==, >=, >, <>, !=
# in expression
# := expression
# default expression

#demand and delivery#
# Demand quantity of product y on period t for customer c on scenario s
param D    'demand'    {1..T,P,C}, >= 0;
# display sum{l in C, p in Y, t in 1..T: t=1} D[t,p,l];

#production#
#if resource "r" is of product "p"
param RW    'resource mtx'    {f in F,R[f],Y}, binary;

#resource eficiency
param EF    'eficiency'    {f in F,R[f],1..T}, >= 0, <= 1, default 1;

#lot size of product "p" on local "l"
param LS 'lot-size'    {l in L, p in P}, >= 0, default 1;

#Bill of Materials - qty of component "pi" to produce any product
param BL 'bill of mat'    {pi in X, p in Y}, >= 0,    default 1;

#Resource consumption of "r" to produce "y"
param MC 'tons per hour'    {f in F,R[f],Y}, >= 0, default 3;

#default capacity on time bucket t
param AH 'avail hours'    {1..T}, > 0;

# Number of resources
param NM    'no machines'    {f in F, R[f]}, >= 0, integer, default 1;

# preventive maintenance on time bucket t
param PM 'prev manint'    {f in F,R[f],1..T}, >= 0, default 0;

# preventive maintenance time less than available time for production
check{f in F,r in R[f],t in 1..T}: PM[f,r,t] < AH[t]*NM[f,r];

#Machine Yield
param MY 'machine yield'    {f in F, R[f]}, >= 0, <= 1, default 1;

#Extra capacity available on machine "r" plant "l" and "t"
param AX    'extra capa'    {f in F,R[f],1..T}, >= 0, default 266;

# Available capacity can not be negative or zero
check{t in 1..T,f in F, r in R[f]}: (AH[t]*NM[f,r]-PM[f,r,t])*(EF[f,r,t]*MY[f,r]) + AX[f,r,t] > 0;

#Availability of product "p" on location "v" and "t"
# param AV 'availability'    {l in V,p in P,t in 1..T}, >= 0, default 0;
param AV 'availability'    {l in V,p in P}, >= 0, default 0;

#distribution#
#Initial stock of finished product "p" on location "l"
param Io 'init invent'    {L,P}, >= 0, default 0;

#Safety stock of finished product "p" on location "l"
param SS 'safety stock'    {l in L,p in P,t in 1..T}, >= 0, default 0;

#Maximum stock of finished product "p" on location "l"
param MS 'max stock'    {l in L,p in P,t in 1..T} >= 0, default 100;

# max stock greater than safety stock
check{l in L,p in P,t in 1..T}: MS[l,p,t] >= SS[l,p,t];

#Final inventory of finished product "p" on location "l"
param FI 'final invent'    {l in L,p in P}, >= 0, default 0;

check{l in L,p in P, t in 1..T: t=T}: FI[l,p] >= SS[l,p,t];
check{l in L,p in P, t in 1..T: t=T}: FI[l,p] <= MS[l,p,t];

# #distribution center inbound handling capacity (products units)
# param CI    'cap inbound'    {l in DC, t in 1..T}, >= 0;

# #distribution center outbound handling capacity (products units)
# param CO    'cap outbound'    {l in DC, t in 1..T}, >= 0;

#Finance#
#Revenue of sold finished product
param RC    'revenue'        {Y}, >= 0 ;

#production fixed for machine M of facilitie F
# param PFC 'prod fix cost'    {f in F,R[f]}, >= 0;
param PFC 'prod fix cost'    {f in F}:= 17064;

#production cost of finished product "p"
param PVC 'prod var cost'    {f in F, Y}, >=0;

#extra capacity cost (constraint violation)
param EX 'extr cap cost'    {f in F,R[f]}, >= 0, default 30;

#stock costs
#alterado
#param IC 'invent costs'    {F union DC,P}, >= 0;
param IC 'invent costs'    {F,P}, >= 0, default 0;

#procurement cost of product "p" on location "l"
# param PC 'aquisit cost'    {L,P}, >= 0, default 0;
param PC 'aquisit cost'    {P}, default 0;

#Tax over sold product
/* param TAX    'tax'            {C};

/* param TAXS     'tax on sold'    {l in C,p in Y}:= TAX[l]*RC[p]; */
param TAX 'tax'    {C,Y}, >= 0;

#modal transport capacity of products of location "l" to location "li"
# param TC     'modal cap'        {m in M,(l, li) in LK,P}:=  if
#                               m='M1' then 0 else if
#                               m='M2' then 0 else 0;
param TC 'modal cap'        {M,(l, li) in LK}, >= 0, default 0;

#logistics cost of finished product "p"
param LC    'costs logist'    {M,(l, li) in LK}, >= 0, default 10;

#production not delivered cost of finished product "p"
# param CN    'opport cost'    {l in C,p in Y}:= RC[p];


#export to txt
param financeiro        ,symbolic, default  "01-Glpk-finaceiro.txt";
param compra            ,symbolic, default  "02-Glpk-compra.txt";
param producao          ,symbolic, default  "03-Glpk-producao.txt";
param estoque           ,symbolic, default  "04-Glpk-estoque.txt";
param materiaPrima      ,symbolic, default  "05-Glpk-materiaPrima.txt";
param entrega           ,symbolic, default  "06-Glpk-entrega.txt";
param naoEntrega        ,symbolic, default  "07-Glpk-naoEntrega.txt";
param consumoProducao   ,symbolic, default  "08-Glpk-consumoProducao.txt";
param capacidade        ,symbolic, default  "09-Glpk-capacidade.txt";
param capacidadeExtra   ,symbolic, default  "10-Glpk-capacidadeExtra.txt";
param transporte        ,symbolic, default  "11-Glpk-transporte.txt";
param transporteModal   ,symbolic, default  "12-Glpk-transporteModal.txt";

# Variables
# var    name    alias    domain    atrib, atrib, ... , atrib;
# optional atrib:
# integer
# binary
# >= expression
# <= expression
# = expression


#production of "p" on location  "l" on bucket "t"
# var ap        'production on plant'         {L,P,1..T},>=0;
var ap        'production on plant'         {L,P,1..T},>=0;                 #production of "p" on location  "l" on bucket "t"

#purchase of component "x"
# var re      'purchased'                    {L,P,1..T},>=0;
var re      'purchased'                    {L,P,1..T},>=0;                 #purchase of component "x"

#production of "p" on resource  "r" on bucket "t"
# var y       'activate machine' {f in F,R[f],1..T}, binary;

#production of "p" on resource  "r" on bucket "t"
var ar        'prod on resource'             {f in F,r in R[f],p in P,1..T},>=0;

#production consumption of items "x" on location  "l" on bucket "t"
var bp         'prod consumption'            {L,P,1..T},>=0;

#stock level
var sp         'inventory level'            {l in L,p in P,0..T}, >= 0;

#delivered demand
var de         'delivered'                    {L,P,1..T},>=0;

#Used capacity of resource r on bucket t
var cc         'consump capty'                {f in F,R[f],t in 1..T},>=0;

#extra capacity needed
var ce        'extra cap'                     {f in F,R[f],t in 1..T},>=0,<= 1;

#not delivered demand
var dn         'not delivered'                {L,P,1..T},>=0;

#qty transported
var tx      'transport'                    {M,LK,P,1..T},>=0;

var expected_profit;
var expected_profit_1;
var expected_profit_2;
var total_costs;
var delivery_cost;
var delivery_cost_1;
var delivery_cost_2;
var not_delivered_cost;
var production_cost_fix;
var production_cost_fix_1;
var production_cost_fix_2;
var production_cost_var;
var production_cost_var_1;
var production_cost_var_2;
var procurement_cost;
var procurement_cost_1;
var procurement_cost_2;
var extra_capacity_cost;
var extra_capacity_cost_1;
var extra_capacity_cost_2;
var inventory_cost;
var inventory_cost_1;
var inventory_cost_2;
var revenue;
var revenue_1;
var revenue_2;
var tax_rate;

var total_demand;
var delivered;
var not_delivered;
var production{l in L,t in 1..T};
var production_1{l in L,t in 1..T};
var production_2{l in L,t in 1..T};

# Objective statement
# minimize    name    alias    domain    :    expression ;
# maximize    name    alias    domain    :    expression ;


# Check statement
# check    domain :     expression ;
#check: sum{l in F, p in Y, t in 1..T} ap[l,p,t,s] =  sum{l in L, p in P, t in 1..T: l in C} (de[l,p,t] + dn[l,p,t]);

# Display statement
# display    domain :     item, ... , item ;
# display    'x = ', x, 'y = ', y, 'z = ', z ;

#minimize     Total_Cost : total_costs;
maximize    Expected_Profit: expected_profit;

# Constraints
# s.t.    name    alias    domain    :    expression,     = expression;
# s.t.    name    alias    domain    :    expression,     >= expression;
# s.t.    name    alias    domain    :    expression,     <= expression;
# s.t.    name    alias    domain    :    expression,     <= expression, <= expression;
# s.t.    name    alias    domain    :    expression,     >= expression, >= expression;

# Domain Constraing: It's not allowed the production of any product
# (raw material or finished product) on suppliers.
s.t. R_domain_product_P     'domain product P' {l in L diff F, p in P, t in 1..T}: ap[l,p,t] = 0;
s.t. R_domain_prod_RM_F     'domain prod RM F' {l in F, p in P diff Y, t in 1..T}: ap[l,p,t] = 0;
s.t. R_domain_consumpt_Y    'domain consumpt Y'{l in L, p in P diff X, t in 1..T}: bp[l,p,t] = 0;
s.t. R_domain_consumpt_X    'domain consumpt X'{l in L diff F, p in P diff Y, t in 1..T}: bp[l,p,t] = 0;
s.t. R_domain_inventor_Y    'domain inventor Y'{l in L diff F, p in P diff X, t in 1..T}: sp[l,p,t] = 0;
s.t. R_domain_inventor_X    'domain inventor X'{l in L diff F, p in P diff Y, t in 1..T}: sp[l,p,t] = 0;
s.t. R_domain_transp_RM     'domain transp RM' {m in M,(l, li) in LK diff L_VF, p in P diff Y, t in 1..T}: tx[m,l,li,p,t] = 0;
#s.t. R_domain_transp_FP     'domain transp FP' {m in M,(l, li) in L_VF, p in P diff X, t in 1..T}: tx[m,l,li,p,t] = 0;
s.t. R_domain_transp_LL     'domain transp LL' {m in M,(l, li) in LK, p in P, t in 1..T : l = li}: tx[m,l,li,p,t] = 0;
# s.t. R_domain_transp_M      'domain transp M'  {m in M,(l, li) in L_VF, p in P diff Y, t in 1..T: m != 'M1' }: tx[m,l,li,p,t] = 0;
s.t. R_domain_deliver       'domain deliver'   {l in L diff C, p in P, t in 1..T}: de[l,p,t] = 0;
#s.t. R_domain_purch_FP      'domain purch FP'  {l in L, p in P diff X, t in 1..T}: re[l,p,t] = 0;
#s.t. R_domain_purch_RM      'domain purch RM'  {l in L diff V, p in P diff Y, t in 1..T}: re[l,p,t] = 0;
s.t. R_domain_purch_RM      'domain purch RM'  {l in L diff V, p in P, t in 1..T}: re[l,p,t] = 0;

# display L diff F,P,T;                                # R1
# display F,R,P diff Y;                                # R2
# display L, P diff X;                                 # R3
# display L diff (V union F), P;                     # R4
# display L diff (V union F), P diff Y;           # R5
# display L diff (F union DC),P diff X;          # R6
# display M,LK diff L_VF,P diff Y;        # R7
# display M,L_VF, P diff X;                  # R8
# display L diff C,P;                                   # R11
# display L, P diff X;                                 # R12
# display L diff V, P diff Y;                        # R13


# Inventory Constraint: Finished product inventory must be
# greatter than a production rate for each plant.
s.t. R_initial_inventory 'initial inventory' {l in L, p in P}: sp[l,p,0] = Io[l,p];

#stock level
s.t. R_SS_inventory 'safety inventory' {l in L, p in P, t in 1..T}: sp[l,p,t] >= SS[l,p,t];
s.t. R_MS_inventory 'maximum inventory' {l in L, p in P, t in 1..T}: sp[l,p,t] <= MS[l,p,t];
s.t. R_FS_inventory 'final inventory' {l in F , p in Y, t in 1..T: t=T}: sp[l,p,t] >= FI[l,p];

s.t. R_purch_AV      'purch availability'  {l in V, p in P, t in 1..T}: LS[l,p]*re[l,p,t] <= AV[l,p];

# Material Flow Constraint : Inbound transport of raw material from suppliers to plants and outbount transport of finished products to customers on the first bucket
# s.t. R_material_flow_initial 'material flow initial' {l in L, p in P, t in 1..T: t = 1}: sum{m in M,(li, l) in LK} tx[m,li,l,p,t] + LS[l,p]*ap[l,p,t] + Io[l,p] + LS[l,p]*re[l,p,t] =  sum{m in M,(l, li) in LK} tx[m,l,li,p,t] + de[l,p,t] + sp[l,p,t] + bp[l,p,t];

# Material Flow Constraint : Inbound transport of raw material from suppliers to plants and outbount transport of finished products to customers on every bucket
s.t. R_material_flow_periods 'material flow periods' {l in L, p in P, t in 1..T}: sum{m in M,(li, l) in LK} tx[m,li,l,p,t] + LS[l,p]*ap[l,p,t] + sp[l,p,t-1] + LS[l,p]*re[l,p,t] = sum{m in M,(l, li) in LK} tx[m,l,li,p,t] + de[l,p,t] + sp[l,p,t] + bp[l,p,t];

# Limited DC handling inbound
#s.t. R_limited_inbound 'limited inbound handling' {l in DC, t in 1..T}: sum{m in M,(li, l) in LK, p in Y} tx[m,li,l,p,t] <= CI[l,t];

# Limited DC handling outbound
#s.t. R_limited_outbound 'limited outbound handling' {l in DC, t in 1..T}: sum{m in M,(l, li) in LK, p in Y} tx[m,l,li,p,t] <= CO[l,t];

# Product Data Structure (Route) Constraint and capacity consumption for each plant.
s.t. R_product_structure 'product structure' {f in F,r in R[f], t in 1..T}: sum{p in Y}(ar[f,r,p,t]*RW[f,r,p])*(MC[f,r,p]^-1) = cc[f,r,t];

# Capacitated Resource Constraint per bucket
# s.t. R_limited_capacity 'limited capacity' {f in F, r in R[f], t in 1..T}: cc[f,r,t] <= (((AH[t]*NM[f,r]) - PM[f,r,t]) * (EF[f,r,t]*MY[f,r])) * y[f,r,t] + ce[f,r,t]*AX[f,r,t];
s.t. R_limited_capacity 'limited capacity' {f in F, r in R[f], t in 1..T}: cc[f,r,t] <= (((AH[t]*NM[f,r]) - PM[f,r,t]) * (EF[f,r,t]*MY[f,r])) + ce[f,r,t]*AX[f,r,t];

# Extra capacity activated only if production is activated
# s.t. R_limited_extra_cap 'limited extra' {f in F, r in R[f], t in 1..T}: ce[f,r,t] <= y[f,r,t];
s.t. R_limited_extra_cap 'limited extra' {f in F, r in R[f], t in 1..T}: ce[f,r,t] <= 1;

# Production Constraint for each plant.
s.t. R_plant_production 'plant production' {l in F, r in R[l], p in Y, t in 1..T}: ar[l,r,p,t]*RW[l,r,p] = LS[l,p]*ap[l,p,t];
# s.t. R_plant_F1_production 'plant F1 production' {l in F, r in R[l], p in Y, t in 1..T : l = 'F1'}: ar[l,r,p,t]*RW[l,r,p] = LS[l,p]*ap[l,p,t];
# s.t. R_plant_F2_production 'plant F2 production' {l in F, r in R[l], p in Y, t in 1..T : l = 'F2'}: ar[l,r,p,t]*RW[l,r,p] = LS[l,p]*ap[l,p,t];

# Bill of Materials Constraint(B.O.M.): Finished product production requires raw material proportional consumption
# s.t. R_bill_of_Materials 'bill of Materials' {l in F, p in Y, t in 1..T}: sum{pi in X} (BL[pi,p]^-1)*bp[l,pi,t] = LS[l,p]*ap[l,p,t];
s.t. R_bill_of_Materials 'bill of Materials' {l in F, pi in X, t in 1..T}: bp[l,pi,t] = sum{p in Y}BL[pi,p]*LS[l,p]*ap[l,p,t];

# Transport capacity Constraint
# s.t. R_transp_capacity 'transp capacity' {m in M,(l, li) in LK,p in P, t in 1..T}: tx[m,l,li,p,t] <= TC [m,l,li,p] ;
s.t. R_transp_capacity 'transp capacity' {m in M,(l, li) in LK,t in 1..T}: sum{p in P}tx[m,l,li,p,t] <= TC[m,l,li] ;

# Delivered and not delivered Constraint
s.t. R_delivery 'delivery' {l in C,p in Y,t in 1..T}: de[l,p,t] = D[t,p,l] - dn[l,p,t];


# Objective Function
s.t. R_total_costs 'total costs': total_costs =

# sum{s in 1..S} PROB[s]*(
sum {m in M, (l, li) in LK,p in Y,t in  1..T} (LC[m,l,li])*tx[m,l,li,p,t] + # delivery_cost
# sum{l in C,p in Y, t in  1..T} (CN[l,p])*dn[l,p,t]+                          # not_delivered_cost
# sum{l in F, r in R[l], t in 1..T} (PFC[l,r])*y[l,r,t]+               # production_cost_fix
sum{l in F, t in 1..T} (PFC[l])+               # production_cost_fix
sum{l in F, p in Y, t in 1..T} (PVC[l,p])*ap[l,p,t]+                         # production_cost_var
# sum {l in V, p in P, t in 1..T} (PC[l,p])*re[l,p,t]+                         # procurement_cost
sum {l in V, p in P, t in 1..T} (PC[p])*re[l,p,t]+                         # procurement_cost
sum {l in F, r in R[l], t in 1..T} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) +                       # extra_capacity_cost
sum{l in F, p in P, t in 1..T}(IC[l,p])*sp[l,p,t]# inventory_cost plant

# )
;
#alterado
#sum{l in DC, p in Y, t in 1..T}(IC[l,p])*sp[l,p,t]                            # inventory_cost dc


s.t. R_expected_profit 'expected profit': expected_profit =

# sum{s in 1..S} PROB[s]*(
sum {l in C,p in Y, t in  1..T} RC[p]*(1-TAX[l,p])*de[l,p,t] -               # revenue
(
sum {m in M, (l, li) in LK,p in Y,t in  1..T} (LC[m,l,li])*tx[m,l,li,p,t] + # delivery_cost
# sum{l in C,p in Y, t in  1..T} (CN[l,p])*dn[l,p,t]+                          # not_delivered_cost
# sum{l in F, r in R[l], t in 1..T} (PFC[l,r])*y[l,r,t]+               # production_cost_fix
sum{l in F, t in 1..T} (PFC[l])+               # production_cost_fix
sum{l in F, p in Y, t in 1..T} (PVC[l,p])*ap[l,p,t]+                         # production_cost_var
sum {l in V, p in P, t in 1..T} (PC[p])*re[l,p,t]+                         # procurement_cost
sum {l in F, r in R[l], t in 1..T} EX[l,r]*(ce[l,r,t]*AX[l,r,t])+                       # extra_capacity_cost
sum{l in F, p in P, t in 1..T}(IC[l,p])*sp[l,p,t]                            # inventory_cost plant

# )
);

s.t. R_expected_profit_1 'expected profit': expected_profit_1 =

# sum{s in 1..S} PROB[s]*(
sum {l in C,p in Y, t in  1..T: t=1} RC[p]*(1-TAX[l,p])*de[l,p,t] -               # revenue
(
sum {m in M, (l, li) in LK,p in Y,t in  1..T: t=1} (LC[m,l,li])*tx[m,l,li,p,t] + # delivery_cost
# sum{l in C,p in Y, t in  1..T} (CN[l,p])*dn[l,p,t]+                          # not_delivered_cost
sum{l in F, t in 1..T: t=1} (PFC[l])+               # production_cost_fix
sum{l in F, p in Y, t in 1..T: t=1} (PVC[l,p])*ap[l,p,t]+                         # production_cost_var
sum {l in V, p in P, t in 1..T: t=1} (PC[p])*re[l,p,t]+                         # procurement_cost
sum {l in F, r in R[l], t in 1..T: t=1} EX[l,r]*(ce[l,r,t]*AX[l,r,t])+                       # extra_capacity_cost
sum{l in F, p in P, t in 1..T: t=1}(IC[l,p])*sp[l,p,t]                            # inventory_cost plant
# )
);

s.t. R_expected_profit_2 'expected profit': expected_profit_2 =

# sum{s in 1..S} PROB[s]*(
sum {l in C,p in Y, t in  1..T: t=2} RC[p]*(1-TAX[l,p])*de[l,p,t] -               # revenue
(
sum {m in M, (l, li) in LK,p in Y,t in  1..T: t=2} (LC[m,l,li])*tx[m,l,li,p,t] + # delivery_cost
# sum{l in C,p in Y, t in  1..T} (CN[l,p])*dn[l,p,t]+                          # not_delivered_cost
sum{l in F, t in 1..T: t=2} (PFC[l])+               # production_cost_fix
sum{l in F, p in Y, t in 1..T: t=2} (PVC[l,p])*ap[l,p,t]+                         # production_cost_var
sum {l in V, p in P, t in 1..T: t=2} (PC[p])*re[l,p,t]+                         # procurement_cost
sum {l in F, r in R[l], t in 1..T: t=2} EX[l,r]*(ce[l,r,t]*AX[l,r,t])+                       # extra_capacity_cost
sum{l in F, p in P, t in 1..T: t=2}(IC[l,p])*sp[l,p,t]                             # inventory_cost plant
);


s.t. R_revenue              'objective': revenue = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
s.t. R_delivery_cost        'objective': delivery_cost = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_not_delivered_cost   'objective': not_delivered_cost = /* sum{s in 1..S} PROB[s]*( */ sum{l in C,p in Y, t in  1..T} (CN[l,p])*dn[l,p,t] ;
s.t. R_production_cost_fix  'objective': production_cost_fix = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T} (PFC[l]) ;
s.t. R_production_cost_var  'objective': production_cost_var = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T} (PVC[l,p])*ap[l,p,t] ;
s.t. R_procurement_cost     'objective': procurement_cost = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T} (PC[p])*re[l,p,t] ;
s.t. R_extra_capacity_cost  'objective': extra_capacity_cost = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
s.t. R_inventory_cost       'objective': inventory_cost = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T}(IC[l,p])*sp[l,p,t] ;
s.t. R_production           'objective'  {l in F, t in 1..T}: production[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

s.t. R_revenue_1              'objective': revenue_1 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 1} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
s.t. R_delivery_cost_1        'objective': delivery_cost_1 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 1} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_not_delivered_cost   'objective': not_delivered_cost = /* sum{s in 1..S} PROB[s]*( */ sum{l in C,p in Y, t in  1..T} (CN[l,p])*dn[l,p,t] ;
s.t. R_production_cost_fix_1  'objective': production_cost_fix_1 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 1} (PFC[l]) ;
s.t. R_production_cost_var_1  'objective': production_cost_var_1 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 1} (PVC[l,p])*ap[l,p,t] ;
s.t. R_procurement_cost_1     'objective': procurement_cost_1 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 1} (PC[p])*re[l,p,t] ;
s.t. R_extra_capacity_cost_1  'objective': extra_capacity_cost_1 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 1} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
s.t. R_inventory_cost_1       'objective': inventory_cost_1 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 1}(IC[l,p])*sp[l,p,t] ;
s.t. R_production_1           'objective'  {l in F, t in 1..T: t = 1}: production_1[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_2     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_2  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_2       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_2           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_2              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_2        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_2  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_2  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_11     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_11  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_11       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_11           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# s.t. R_revenue_12              'objective': revenue_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in C,p in Y, t in  1..T: t = 2} RC[p]*(1-TAX[l,p])*de[l,p,t] ;
# s.t. R_delivery_cost_12        'objective': delivery_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {m in M, (l, li) in LK,p in Y,t in  1..T: t = 2} (LC[m,l,li])*tx[m,l,li,p,t] ;
# s.t. R_production_cost_fix_12  'objective': production_cost_fix_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, t in 1..T: t = 2} (PFC[l]);
# s.t. R_production_cost_var_12  'objective': production_cost_var_2 = /* sum{s in 1..S} PROB[s]*(  */sum{l in F, p in Y, t in 1..T: t = 2} (PVC[l,p])*ap[l,p,t] ;
# s.t. R_procurement_cost_12     'objective': procurement_cost_2 = /* sum{s in 1..S} PROB[s]*(  */sum {l in V, p in P, t in 1..T: t = 2} (PC[p])*re[l,p,t] ;
# s.t. R_extra_capacity_cost_12  'objective': extra_capacity_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum {l in F, r in R[l], t in 1..T: t = 2} EX[l,r]*(ce[l,r,t]*AX[l,r,t]) ;
# s.t. R_inventory_cost_12       'objective': inventory_cost_2 = /* sum{s in 1..S} PROB[s]*( */ sum{l in F, p in P, t in 1..T: t = 2}(IC[l,p])*sp[l,p,t] ;
# s.t. R_production_12           'objective'  {l in F, t in 1..T: t = 2}: production_2[l,t] = /* sum{s in 1..S} PROB[s]*( */ sum{p in Y}ap[l,p,t] ;

# Solve statement
solve;



# display{l in F, p in Y, t in 1..T}: (PVC[l,p])*(ap[l,p,t]);
# display{l in F, p in Y, t in 1..T}: (PVC[l,p]);
# display{l in F, p in Y, t in 1..T}: ap[l,p,t];
# display{l in V, p in P, t in 1..T}: (PC[l,p])*re[l,p,t];
# display sum{m in M, (l, li) in LK,p in Y,t in  1..T:t=1} (LC[m,l,li])*tx[m,l,li,p,t];

# display{l in F, r in R[l], p in Y, t in 1..T}: ar[l,r,p,t];
# display{l in F, p in Y, t in 1..T}: ap[l,p,t];
# display{f in F, r in R[f], t in 1..T}: cc[f,r,t];
# display{f in F, r in R[f], t in 1..T}: (((AH[t]*NM[f,r]) - PM[f,r,t]) * (EF[f,r,t]*MY[f,r]));
# display{f in F, r in R[f], t in 1..T}: ce[f,r,t]*AX[f,r,t];


# display{f in F, r in R[f], t in 1..T}: cc[f,r,t];
# display{f in F, r in R[f], t in 1..T}: round(ce[f,r,t]*AX[f,r,t],0);
# display{m in M, (l, li) in LK, p in P,t in  1..T: tx[m,l,li,p,t] > 0} tx[m,l,li,p,t];
# display ap;        #'production on plant'         {L,P,1..T},>=0;                 #production of "p" on location  "l" on bucket "t"
# display ar;        #'prod on resource'             {f in F,R[f],P,1..T},>=0;         #production of "p" on resource  "r" on bucket "t"
# display bp;        #'prod consumption'            {L,P,1..T},>=0;                 #production consumption of items "x" on location  "l" on bucket "t"
# display sp;         #'inventory level'            {L,P,1..T},>=0;                 #stock level
# display tx;      #'transport'                    {M,L,L,P,1..T},>=0;            #qty transported
# display de;         #'delivered'                    {L,P,1..T},>=0;                 #delivered demand
# display re;      #'purchased'                    {L,P,1..T},>=0;                 #purchase of component "x"
# display c;          #'consump capty'                {f in F,R[f],t in 1..T},>=0,<= AH[t];     #Used capacity of resource r on bucket t
# display ce;        #'extra cap'                     {f in F,R[f],t in 1..T},>=0,<= AH[t];     #extra capacity needed
# display dn;         #'not delivered'                {L,P,1..T},>=0;                 #not delivered demand
# display txlm;    #'multi lot'                    {L,L,1..T}, >=0;                #multiple lot of transport
# display y;       #'activate machine'          {f in F,R[f],1..T}, binary;    #production of "p" on resource  "r" on bucket "t"

# Printf statement
# printf    domain : format, expression, ... , expression ;
# printf    domain : format, expression, ... , expression > filename ;        >  Create a new empty file
# printf    domain : format, expression, ... , expression >> filename ;    >> Append output to existing file

# For statement
# for    domain :     statement ;
# for    domain :     { statement ... statement } ;



#################################################################

printf "\n==================================================================\n"                    > financeiro;
printf "RESULTADO FINANCEIRO\tPERIODO 1\tPERIODO 2\tTOTAL\n"                    > financeiro;
printf "==================================================================\n"                    > financeiro;
printf "Receita:\t\t%-9.2f\t%-9.2f\t%-9.2f\n", revenue_1, revenue_2, revenue            >> financeiro;
printf "Custo fixo prod:\t%-9.2f\t%-9.2f\t%-9.2f\n", production_cost_fix_1, production_cost_fix_2, production_cost_fix        >> financeiro;
printf "Custo var horas ext:\t%-9.2f\t%-9.2f\t%-9.2f\n", extra_capacity_cost_1, extra_capacity_cost_2, extra_capacity_cost        >> financeiro;
printf "Custo var producao:\t%-9.2f\t%-9.2f\t%-9.2f\n", production_cost_var_1, production_cost_var_2, production_cost_var        >> financeiro;
printf "Custo var compras  :\t%-9.2f\t%-9.2f\t%-9.2f\n", procurement_cost_1, procurement_cost_2, procurement_cost              >> financeiro;
printf "Custo var estoques :\t%-8.2f\t%-8.2f\t%-8.2f\n", inventory_cost_1, inventory_cost_2, inventory_cost                >> financeiro;
printf "Custo var transport:\t%-9.2f\t%-9.2f\t%-9.2f\n", delivery_cost_1, delivery_cost_2, delivery_cost                  >> financeiro;
printf "__________________________________________________________________\n"                   >> financeiro;
printf "Lucro Operacional:\t%-9.2f\t%-9.2f\t%-9.2f\n", expected_profit_1, expected_profit_2, expected_profit                 >> financeiro; 


printf "\n\n=======CONSUMO DE MAT.PRIMA=======\n"    > materiaPrima;
printf "PERIODO\tLOCAL\tPRODUTO\tQUANTIDADE\n"   >> materiaPrima;
for { t in 1..T,l in L, p in P: bp[l,p,t] > 0}     printf "[%d]\t[%s]\t[%s]:\t%.2f\n",t,l,p,bp[l,p,t]     >> materiaPrima;


printf "\n\n=============PRODUCAO=============\n"    > producao;
printf "PERIODO\tLOCAL\tPRODUTO\tQUANTIDADE\n"   >> producao;
for { t in 1..T,l in L, p in P: ap[l,p,t] > 0}     printf "[%d]\t[%s]\t[%s]:\t%.2f\n",t,l,p,LS[l,p]*ap[l,p,t]     >> producao;


printf "\n\n==========ESTOQUE DE PRODUTO NOS LOCAIS =========\n" > estoque;
printf "PERIODO\tLOCAL\tPRODUTO\tMIN\tQUANT\tMAX\t(%%)\n"   >> estoque;
for { t in 1..T,l in L, p in P: sp[l,p,t] > 0}     printf "[%d]\t[%s]\t[%s]:\t%d\t%d\t%d\t%d%%\n",t,l,p,SS[l,p,t],sp[l,p,t],MS[l,p,t],(sp[l,p,t]/MS[l,p,t])*100   >> estoque;

printf "\n\n===============PROD.MAQUINAS===============\n"   > consumoProducao;
printf "PERIODO\tLOCAL\tMAQUINA\tPRODUTO\tQUANTIDADE\n"   >> consumoProducao;
for {t in 1..T,f in F, r in R[f],p in P: ar[f,r,p,t] > 0}     printf "[%d]\t[%s]\t[%s]\t[%s]:\t%.2f\n",t,f,r,p,ar[f,r,p,t]   >> consumoProducao; 


printf "\n\n==================CAP.MAQUINAS=================\n" > capacidade;
printf "PERIODO\tLOCAL\tMAQUINA\tATIVA?\tQUANT\t(%%)OCUP\n"   >> capacidade;
for { t in 1..T,f in F, r in R[f]}     printf "[%d]\t[%s]\t[%s]\t[%.2f]\t%.2f\t%.2f%%\n" ,t,f,r,1,cc[f,r,t], (cc[f,r,t]/(((AH[t]*NM[f,r]) - PM[f,r,t]) *(EF[f,r,t]*MY[f,r])))*100    >> capacidade; 


printf "\n\n=========CAPACIDADE.EXTRA=========\n"   > capacidadeExtra;
printf "PERIODO\tLOCAL\tMAQUINA\tQUANTIDADE\n"    >> capacidadeExtra;
for {t in 1..T,f in F, r in R[f]: ce[f,r,t] > 0.1}     printf "[%d]\t[%s]\t[%s]:\t%.2f\n",t,f,r,ce[f,r,t]      >> capacidadeExtra; 


printf "\n\n===========TRANSPORTE DE PROD. ACAB===============\n"     > transporte;
printf "PERIODO\tMODAL\tLOCAL\tLOCAL\tPRODUTO\tQUANTIDADE\n"   >> transporte;
for { t in 1..T,m in M,(l, li) in LK,p in Y: tx[m,l,li,p,t] > 0}     printf "[%d]\t[%s]\t[%s]\t[%s]\t[%s]:\t%.2f\n",t,m,l,li,p,tx[m,l,li,p,t]    >> transporte; 


printf "\n\n===============TRANSPORTE.MODAL================\n"   > transporteModal;
printf "PERIODO\tMODAL\tLOCAL\tLOCAL\tQUANT\t(%%)OCUP\n"   >> transporteModal;
for { t in 1..T,m in M,(l, li) in (LK diff L_VF), p in P: tx[m,l,li,p,t] > 0 and TC [m,l,li] > 0}   printf "[%d]\t[%s]\t[%s]\t[%s]:\t%d\t%d%%\n",t,m,l,li,tx[m,l,li,p,t], (tx[m,l,li,p,t]/TC [m,l,li])*100    >> transporteModal; 


printf "\n\n=============ENTREGA==============\n"   > entrega;
printf "PERIODO\tLOCAL\tPRODUTO\tQUANTIDADE\n"    >> entrega;
for { t in 1..T,l in L, p in P: de[l,p,t] > 0}     printf "[%d]\t[%s]\t[%s]:\t%.2f\n",t,l,p,de[l,p,t]     >> entrega; 


printf "\n\n============NAO.ENTREGA===========\n"    > naoEntrega;
printf "PERIODO\tLOCAL\tPRODUTO\tQUANTIDADE\n"   >> naoEntrega;
for { t in 1..T,l in L, p in P: dn[l,p,t] > 0}     printf "[%d]\t[%s]\t[%s]:\t%.2f\n",t,l,p,dn[l,p,t]     >> naoEntrega; 


#Time set
#----------------------------------------------------------------------------------------------------------------------------------------------#
param agora:= gmtime() -3*3600;
param tempo, symbolic, := time2str(agora, "%d de %b de 20%y at %T");
#----------------------------------------------------------------------------------------------------------------------------------------------#
printf "\n\n_____________________________________________________\n";
# printf:"By: Joao Flavio F. Almeida [UFMG]\t\n"                                                           ;    # >>financeiro;
printf:"At: %s\t\n",tempo                                                                                ;    # >>financeiro;


end;

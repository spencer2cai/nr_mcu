#include <fstream>
#include <string>
#include <iostream>
#include <algorithm>
#include <iomanip>

using namespace std;

#define MAX_MAKER 10000      //最大的编译代码条数


struct Code_Type { string  name; unsigned int data;unsigned int type;};   

struct Code_Type Code_Array[] = {
    {   "read",     0x01,   0,  }, 
    {   "write",    0x02,   0,  }, 
    {   "jump",     0x11,   0,  }, 
    {   "jumpe",    0x12,   0,  }, 
    {   "jumpn",    0x13,   0,  }, 
    {   "load",     0x21,   0,  }, 
    {   "save",     0x22,   0,  }, 
    {   "set",      0x23,   0,  }, 
    {   "add",      0x31,   0,  }, 
    {   "and",      0x32,   0,  }, 
    {   "or",       0x33,   0,  }, 
    {   "xor",      0x34,   0,  }, 
    {   "shiftl",   0x35,   0,  }, 
    {   "shiftr",   0x36,   0,  }, 
    {   "shiftl4",  0x37,   0,  }, 
    {   "shiftr4",  0x38,   0,  }, 
    {   "delay",    0x41,   0,  }, 
    {   "callon",   0x51,   0,  }, 
    {   "callbk",   0x52,   0,  }, 
//////////////////////////////////////////
    {   "end",  0,  0,   },  //列表结束,实际没有end这条指令
};



string rmLastChar(string OldSt);//删除最后一个字符
int CheckOptCode(string st);//检查是否是指令
int CheckOptData(string st);  //检查是否是操作数
int CheckOptVar(string st);  //检查是否是变量
int CheckCodeSession(string st);//检查是否是代码段标号
int CheckOptSigCode(string st);//检查是否是单操作码指令
int TransOptCode(string st);  //翻译指令
int TransOptData(string st);  //翻译数据
int TransChar(char ch);  //翻译字符
int TransVar(string st);  //翻译变量
int TransSession(string st);  //翻译代码段标号

string  StrData[MAX_MAKER];  //所有代码放在临时空间
string  VariableTag[MAX_MAKER]; //变量列表
string  OptTag[MAX_MAKER]; //所有原始指令列表
string  OptCode[MAX_MAKER][3];//处理过之后指令列表，三列
unsigned int     OptCodehex[MAX_MAKER][2];//三列形式的指令列表转换成HEX
unsigned int     StrCnt=0;//总伪指令数
unsigned int     VarNum=0;//总变量数
unsigned int     OptNum=0;//总代码部分数目
unsigned int     OptCodeNum=0;//有效的代码条数



int main(int argc, char const *argv[])
{
    ifstream infile("code.txt");
    ofstream dbg("debug.txt");
    ofstream hexout("hexout.txt");

    //1.提取源代码，删除注释
    dbg<<"1.get source code :"<<endl;
    while((infile>>StrData[StrCnt])&&(StrCnt<MAX_MAKER)) {
        if((StrData[StrCnt].size()>1)&&(StrData[StrCnt][0]=='/')&&(StrData[StrCnt][1]=='/')){;}
        else{
            dbg<<StrData[StrCnt]<<endl;
            StrCnt++;
        }
    }//删除注释
    dbg<<"-----------------------------------"<<endl;

    //2.提取源代码中变量
    dbg<<"2.variable check : "<<endl;
    for(int i=0,checking=0;i<StrCnt;i++){//提取变量列表
        int len=StrData[i].size();
        if(StrData[i].compare("VARIABLE_TAG#")==0){
            cout<<"VARIABLE_TAG checked"<<endl;
            checking=1;
        }
        if((StrData[i][len-1]=='#')&&(StrData[i].compare("VARIABLE_TAG#")!=0))checking=0;
        if((checking==1)&&(StrData[i][len-1]!='#')) {
            VariableTag[VarNum]=rmLastChar(StrData[i]);
            dbg<<VariableTag[VarNum]<<endl;
            VarNum++;
        }
    }
    dbg<<"-----------------------------------"<<endl;

    //3.提取代码
    dbg<<"3.code list check : "<<endl;
    for(int i=0,checking=0;i<StrCnt;i++){//提取代码指令列表
        int len=StrData[i].size();
        if(StrData[i].compare("CODE_TAG#")==0){
            cout<<"CODE_TAG checked"<<endl;
            checking=1;
        }
        if((StrData[i][len-1]=='#')&&(StrData[i].compare("CODE_TAG#")!=0))checking=0;
        if((checking==1)&&(StrData[i][len-1]!='#')) {
            OptTag[OptNum]=StrData[i];
            dbg<<OptTag[OptNum]<<endl;
            if(OptTag[OptNum][OptTag[OptNum].size()-1]==';')OptCodeNum++;//有效的条数，用“；”判断
            OptNum++;
        }
    }
    dbg<<"-----------------------------------"<<endl;


    //4.以下开始翻译代码指令
    dbg<<"4.rebase the code to 3XN : "<<endl;
    for(int i=0,j=0;i<OptCodeNum;i++){
        OptCode[i][0]="NULL";//TAG
        while(j<OptNum){
            //1.提取代码段中的标记
            if(OptTag[j][OptTag[j].size()-1]==':') {
                OptCode[i][0]=rmLastChar(OptTag[j]);//标记
                j++;
                continue;
            }
            else {
                string str;
                if(OptTag[j][OptTag[j].size()-1]==';') str=rmLastChar(OptTag[j]);
                else str=OptTag[j];
                if(CheckOptCode(str)==1) {
                    OptCode[i][1]=str;
                    if(CheckOptSigCode(str)==1) OptCode[i][2]="0x0";//单操作符的增加一个0x0的操作数
                }
                else OptCode[i][2]=str;
                if(OptTag[j][OptTag[j].size()-1]==';') {j++;break;}
                else {j++;continue;}
            }
        }
    }
    for(int i=0;i<OptCodeNum;i++){
        dbg<<OptCode[i][0]<<" "<<OptCode[i][1]<<" "<<OptCode[i][2]<<endl;//真正的代码段
    }
    dbg<<"-----------------------------------"<<endl;

    //5.代码从字符转换成HEX，真正的编译
    dbg<<"5.start to compile......!!!!!!"<<endl;
    for(int i=0;i<OptCodeNum;i++){
        if(TransOptCode(OptCode[i][1])==0){
            cout<<"检测到非法汇编指令   ";
            cout<<OptCode[i][1]<<endl;
            getchar();
            return 0;
        }
        else {
            OptCodehex[i][0]=TransOptCode(OptCode[i][1]);//第一列是操作符代码
        }
        int optdata_check = CheckOptData(OptCode[i][2])+CheckOptVar(OptCode[i][2])+CheckCodeSession(OptCode[i][2]);
        if(optdata_check==0){
            cout<<"检测到非法汇编操作数   ";
            cout<<OptCode[i][2]<<endl;
            getchar();
            return 0;
        }else if(optdata_check>1){
            cout<<"检测到汇编操作数重复   ";
            cout<<OptCode[i][2]<<endl;
            getchar();
            return 0;
        }else{
            if(CheckOptData(OptCode[i][2])==1) OptCodehex[i][1] = TransOptData(OptCode[i][2]);
            else if(CheckOptVar(OptCode[i][2])==1) OptCodehex[i][1] = TransVar(OptCode[i][2]);
            else if(CheckCodeSession(OptCode[i][2])==1) OptCodehex[i][1] = TransSession(OptCode[i][2]);
            else {
                cout<<"检测到非法汇编操作数   ";
                cout<<OptCode[i][2]<<endl;
                getchar();
                return 0;
            }
        }
        //
    }
    for(int i=0;i<OptCodeNum;i++){
        dbg<<hex<<setfill('0')<<setw(2)<<OptCodehex[i][0]<<" "<<setfill('0')<<setw(8)<<OptCodehex[i][1]<<" "<<endl;//真正的代码段
    }
    dbg<<"-----------------------------------"<<endl;

    for(int i=0;i<OptCodeNum;i++)cout<<OptCodehex[i][0]<<'\t'<<OptCodehex[i][1]<<endl;
    for(int i=0;i<OptCodeNum;i++)cout<<OptCode[i][0]<<'\t'<<OptCode[i][1]<<'\t'<<OptCode[i][2]<<endl;
    for(int i=0;i<OptCodeNum;i++){
        hexout<<"mem("<<dec<<i<<")<=x\"";
        hexout<<setfill('0')<<setw(2)<<hex<<OptCodehex[i][0];
        hexout<<setfill('0')<<setw(8)<<hex<<OptCodehex[i][1];
        hexout<<"\";"<<endl;
    }
    cout<<"编译正确,回车键结束"<<endl;
    getchar();

    return 0;
} 

string rmLastChar(string OldSt){ //删除最后一个字符
    string NewSt;
    NewSt = OldSt.substr(0, OldSt.size()-1); 
    return NewSt;
}
int CheckOptCode(string st){//检查是否是指令
    int i=0;
    int j;
    for(j=0;Code_Array[j].name.compare("end")!=0;j++){
        if(st.compare(Code_Array[j].name)   ==0) i=1;
    }
    return i;
}
int CheckOptData(string st){  //检查是否是操作数
    int i=0;
    if((st.size()>2)&&(st[0]=='0')&&(st[1]=='x')) i=1;
    return i;
}
int CheckOptVar(string st){  //检查是否是变量
    int r=0;
    for(int i=0;i<VarNum;i++) if(VariableTag[i]==st) r=1;
    return r;
}
int CheckCodeSession(string st){//检查是否是代码段标号
    int r=0;
    for(int i=0;i<OptCodeNum;i++) if(OptCode[i][0]==st) r=1;
    return r;
}
int CheckOptSigCode(string st){//检查是否是单操作码指令
    return 1;
}
int TransOptCode(string st){  //翻译指令
    int i=0;
    int j;
    for(j=0;Code_Array[j].name.compare("end")!=0;j++){
        if(st.compare(Code_Array[j].name)   ==0) i=Code_Array[j].data;
    }
    return i;
}
int TransOptData(string st){  //翻译数据
    int sum=0;
    int len=st.size();
    if((len>2)&&(st[0]=='0')&&(st[1]=='x')) {
        for(int j=2;j<=(len-1);j++){
            sum = sum*16 + TransChar(st[j]);
        }
    }
    return sum;
}
int TransChar(char ch){  //翻译字符
    int c=((int)(ch));
    int r=0;
    if((c>=48)&&(c<=57)) r=(c-48);
    if((c>=65)&&(c<=70)) r=(c-65+10);
    return r;
}
int TransVar(string st){  //翻译变量
    int r=0;
    for(int i=0;i<VarNum;i++) if(VariableTag[i]==st) r=i;
    return r;
} 
int TransSession(string st){ //翻译代码段标号
    int r=0;
    for(int i=0;i<OptCodeNum;i++) if(OptCode[i][0]==st) r=i;
    return r;
} 



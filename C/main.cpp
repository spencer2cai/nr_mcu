#include <fstream>
#include <string>
#include <iostream>
#include <algorithm>
#include <iomanip>

using namespace std;

#define MAX_MAKER 10000      //���ı����������


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
    {   "end",  0,  0,   },  //�б����,ʵ��û��end����ָ��
};



string rmLastChar(string OldSt);//ɾ�����һ���ַ�
int CheckOptCode(string st);//����Ƿ���ָ��
int CheckOptData(string st);  //����Ƿ��ǲ�����
int CheckOptVar(string st);  //����Ƿ��Ǳ���
int CheckCodeSession(string st);//����Ƿ��Ǵ���α��
int CheckOptSigCode(string st);//����Ƿ��ǵ�������ָ��
int TransOptCode(string st);  //����ָ��
int TransOptData(string st);  //��������
int TransChar(char ch);  //�����ַ�
int TransVar(string st);  //�������
int TransSession(string st);  //�������α��

string  StrData[MAX_MAKER];  //���д��������ʱ�ռ�
string  VariableTag[MAX_MAKER]; //�����б�
string  OptTag[MAX_MAKER]; //����ԭʼָ���б�
string  OptCode[MAX_MAKER][3];//�����֮��ָ���б�����
unsigned int     OptCodehex[MAX_MAKER][2];//������ʽ��ָ���б�ת����HEX
unsigned int     StrCnt=0;//��αָ����
unsigned int     VarNum=0;//�ܱ�����
unsigned int     OptNum=0;//�ܴ��벿����Ŀ
unsigned int     OptCodeNum=0;//��Ч�Ĵ�������



int main(int argc, char const *argv[])
{
    ifstream infile("code.txt");
    ofstream dbg("debug.txt");
    ofstream hexout("hexout.txt");

    //1.��ȡԴ���룬ɾ��ע��
    dbg<<"1.get source code :"<<endl;
    while((infile>>StrData[StrCnt])&&(StrCnt<MAX_MAKER)) {
        if((StrData[StrCnt].size()>1)&&(StrData[StrCnt][0]=='/')&&(StrData[StrCnt][1]=='/')){;}
        else{
            dbg<<StrData[StrCnt]<<endl;
            StrCnt++;
        }
    }//ɾ��ע��
    dbg<<"-----------------------------------"<<endl;

    //2.��ȡԴ�����б���
    dbg<<"2.variable check : "<<endl;
    for(int i=0,checking=0;i<StrCnt;i++){//��ȡ�����б�
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

    //3.��ȡ����
    dbg<<"3.code list check : "<<endl;
    for(int i=0,checking=0;i<StrCnt;i++){//��ȡ����ָ���б�
        int len=StrData[i].size();
        if(StrData[i].compare("CODE_TAG#")==0){
            cout<<"CODE_TAG checked"<<endl;
            checking=1;
        }
        if((StrData[i][len-1]=='#')&&(StrData[i].compare("CODE_TAG#")!=0))checking=0;
        if((checking==1)&&(StrData[i][len-1]!='#')) {
            OptTag[OptNum]=StrData[i];
            dbg<<OptTag[OptNum]<<endl;
            if(OptTag[OptNum][OptTag[OptNum].size()-1]==';')OptCodeNum++;//��Ч���������á������ж�
            OptNum++;
        }
    }
    dbg<<"-----------------------------------"<<endl;


    //4.���¿�ʼ�������ָ��
    dbg<<"4.rebase the code to 3XN : "<<endl;
    for(int i=0,j=0;i<OptCodeNum;i++){
        OptCode[i][0]="NULL";//TAG
        while(j<OptNum){
            //1.��ȡ������еı��
            if(OptTag[j][OptTag[j].size()-1]==':') {
                OptCode[i][0]=rmLastChar(OptTag[j]);//���
                j++;
                continue;
            }
            else {
                string str;
                if(OptTag[j][OptTag[j].size()-1]==';') str=rmLastChar(OptTag[j]);
                else str=OptTag[j];
                if(CheckOptCode(str)==1) {
                    OptCode[i][1]=str;
                    if(CheckOptSigCode(str)==1) OptCode[i][2]="0x0";//��������������һ��0x0�Ĳ�����
                }
                else OptCode[i][2]=str;
                if(OptTag[j][OptTag[j].size()-1]==';') {j++;break;}
                else {j++;continue;}
            }
        }
    }
    for(int i=0;i<OptCodeNum;i++){
        dbg<<OptCode[i][0]<<" "<<OptCode[i][1]<<" "<<OptCode[i][2]<<endl;//�����Ĵ����
    }
    dbg<<"-----------------------------------"<<endl;

    //5.������ַ�ת����HEX�������ı���
    dbg<<"5.start to compile......!!!!!!"<<endl;
    for(int i=0;i<OptCodeNum;i++){
        if(TransOptCode(OptCode[i][1])==0){
            cout<<"��⵽�Ƿ����ָ��   ";
            cout<<OptCode[i][1]<<endl;
            getchar();
            return 0;
        }
        else {
            OptCodehex[i][0]=TransOptCode(OptCode[i][1]);//��һ���ǲ���������
        }
        int optdata_check = CheckOptData(OptCode[i][2])+CheckOptVar(OptCode[i][2])+CheckCodeSession(OptCode[i][2]);
        if(optdata_check==0){
            cout<<"��⵽�Ƿ���������   ";
            cout<<OptCode[i][2]<<endl;
            getchar();
            return 0;
        }else if(optdata_check>1){
            cout<<"��⵽���������ظ�   ";
            cout<<OptCode[i][2]<<endl;
            getchar();
            return 0;
        }else{
            if(CheckOptData(OptCode[i][2])==1) OptCodehex[i][1] = TransOptData(OptCode[i][2]);
            else if(CheckOptVar(OptCode[i][2])==1) OptCodehex[i][1] = TransVar(OptCode[i][2]);
            else if(CheckCodeSession(OptCode[i][2])==1) OptCodehex[i][1] = TransSession(OptCode[i][2]);
            else {
                cout<<"��⵽�Ƿ���������   ";
                cout<<OptCode[i][2]<<endl;
                getchar();
                return 0;
            }
        }
        //
    }
    for(int i=0;i<OptCodeNum;i++){
        dbg<<hex<<setfill('0')<<setw(2)<<OptCodehex[i][0]<<" "<<setfill('0')<<setw(8)<<OptCodehex[i][1]<<" "<<endl;//�����Ĵ����
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
    cout<<"������ȷ,�س�������"<<endl;
    getchar();

    return 0;
} 

string rmLastChar(string OldSt){ //ɾ�����һ���ַ�
    string NewSt;
    NewSt = OldSt.substr(0, OldSt.size()-1); 
    return NewSt;
}
int CheckOptCode(string st){//����Ƿ���ָ��
    int i=0;
    int j;
    for(j=0;Code_Array[j].name.compare("end")!=0;j++){
        if(st.compare(Code_Array[j].name)   ==0) i=1;
    }
    return i;
}
int CheckOptData(string st){  //����Ƿ��ǲ�����
    int i=0;
    if((st.size()>2)&&(st[0]=='0')&&(st[1]=='x')) i=1;
    return i;
}
int CheckOptVar(string st){  //����Ƿ��Ǳ���
    int r=0;
    for(int i=0;i<VarNum;i++) if(VariableTag[i]==st) r=1;
    return r;
}
int CheckCodeSession(string st){//����Ƿ��Ǵ���α��
    int r=0;
    for(int i=0;i<OptCodeNum;i++) if(OptCode[i][0]==st) r=1;
    return r;
}
int CheckOptSigCode(string st){//����Ƿ��ǵ�������ָ��
    return 1;
}
int TransOptCode(string st){  //����ָ��
    int i=0;
    int j;
    for(j=0;Code_Array[j].name.compare("end")!=0;j++){
        if(st.compare(Code_Array[j].name)   ==0) i=Code_Array[j].data;
    }
    return i;
}
int TransOptData(string st){  //��������
    int sum=0;
    int len=st.size();
    if((len>2)&&(st[0]=='0')&&(st[1]=='x')) {
        for(int j=2;j<=(len-1);j++){
            sum = sum*16 + TransChar(st[j]);
        }
    }
    return sum;
}
int TransChar(char ch){  //�����ַ�
    int c=((int)(ch));
    int r=0;
    if((c>=48)&&(c<=57)) r=(c-48);
    if((c>=65)&&(c<=70)) r=(c-65+10);
    return r;
}
int TransVar(string st){  //�������
    int r=0;
    for(int i=0;i<VarNum;i++) if(VariableTag[i]==st) r=i;
    return r;
} 
int TransSession(string st){ //�������α��
    int r=0;
    for(int i=0;i<OptCodeNum;i++) if(OptCode[i][0]==st) r=i;
    return r;
} 



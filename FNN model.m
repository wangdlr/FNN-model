close all;
clear;
%FNN model to forecast the next 20 steps
%train and test data setting
data=xlsread('200014pressure--.csv');
x=data(:,1);
y=data(:,2:end);
n=length(y);
max=zeros(1,size(y,2));
min=zeros(1,size(y,2));
for i=1:length(max)
    max(1,i)=y(1,i);
    min(1,i)=y(1,i);
    for j=1:n
        tem=y(j,i);
        if tem>max(1,i)
            max(1,i)=tem;
        end
        if tem<min(1,i)
            min(1,i)=tem;
        end
    end
end
y1=zeros(n,length(max));
y2=zeros(n-2,2*length(max));
y3=zeros(n-2,length(max));
%data normalized
for i=1:n
    for j=1:length(max)
        y1(i,j)=(0.1*(max(1,j)-y(i,j))+0.9*(y(i,j)-min(1,j)))/(max(1,j)-min(1,j));
    end
end
for i=1:n-2
    y2(i,1:length(max))=y1(i,:);
    y2(i,length(max)+1:end)=y1(i+1,:);
    y3(i,:)=y1(i+2,:);
end
%prediction model setting
size=int16(n*0.7);
train_x=y2(1:size,:);
train_y=y3(1:size,:);
test_x=y2(size+1:end,:);
test_y=y3(size+1:end,:);
net1=newff(y2',y3',8*length(max));
net1.trainParam.epochs=5000;
net1.trainParam.goal=0.0001;
net1.trainParam.lr=0.001;
%net1.performFcn='mse';
net1.divideParam.trainRatio=0.7;
net1.divideParam.testRatio=0.3;
net1=train(net1,train_x',train_y');
%prediction on test set for the next 20 steps
%rolling forecasting method
m=20;
len=length(max);
output1(1:len,:)=sim(net1,test_x');
input1(1:2*len,:)=test_x';
if m>1
    for i=2:m
        input1(len*i+1:len*(i+1),:)=output1(len*(i-2)+1:len*(i-1),:);
        output1(len*(i-1)+1:len*i,:)=sim(net1,input1(len*(i-1)+1:len*(i+1),:));
    end
end
%data inverse normalized
for i=1:n-size-2
    for j=1:len
        test_x(i,j)=(test_x(i,j)*(max(1,j)-min(1,j))+0.9*min(1,j)-0.1*max(1,j))/0.8;
        test_x(i,j+len)=(test_x(i,j+len)*(max(1,j)-min(1,j))+0.9*min(1,j)-0.1*max(1,j))/0.8;
        test_y(i,j)=(test_y(i,j)*(max(1,j)-min(1,j))+0.9*min(1,j)-0.1*max(1,j))/0.8;
    end
end
for i=1:m
    for j=1:len
        for k=1:n-size-2
            output1(len*(i-1)+j,k)=(output1(len*(i-1)+j,k)*(max(1,j)-min(1,j))+0.9*min(1,j)-0.1*max(1,j))/0.8;
        end
    end
end
%evaluation indicators calculated
measure1=zeros(m,60);
for i=1:m
    measure1(i,1)=mae(abs(test_y(:,1)-output1(1+len*(i-1),:)'));
    measure1(i,2)=mse(test_y(:,1),output1(1+len*(i-1),:)');
    measure1(i,3)=sqrt(mse(test_y(:,1),output1(1+len*(i-1),:)'));
    measure1(i,4)=mae(abs(test_y(:,2)-output1(2+len*(i-1),:)'));
    measure1(i,5)=mse(test_y(:,2),output1(2+len*(i-1),:)');
    measure1(i,6)=sqrt(mse(test_y(:,2),output1(2+len*(i-1),:)'));
end
%save prediction values and evaluation indicators
tempdata1=xlsread('bp514test1.xlsx');
clear size;
n11=size(tempdata1,2);
clear size;
n12=size(output1,1);
temdata1(:,1:n11)=tempdata1;
temdata1(:,n11+1:n11+n12)=output1';
xlswrite('bp514test1.xlsx',temdata1);
tempdata3=xlsread('bp514test0.xlsx');
clear size;
n15=size(tempdata3,1);
clear size;
n16=size(measure1,1);
temdata3(1:n15,:)=tempdata3;
temdata3(n15+1:n15+n16,:)=measure1;
xlswrite('bp514test0.xlsx',temdata3);

%prediction on typhoon cases
number=[201509,201513,201521,201614,201622,201713,201720,201808,201822];
for i=1:1
    %data processing
    ddata=strcat(num2str(number(i)),'pressure--.csv');
    data1=xlsread(ddata);
    ss=data1(:,2:end);
    nn=length(data1);
    max1=zeros(1,len);
    min1=zeros(1,len);
    for r=1:len
        max1(1,r)=ss(1,r);
        min1(1,r)=ss(1,r);
        for s=1:nn
            temp=ss(s,r);
            if temp>max1(1,r)
                max1(1,r)=temp;
            end
            if temp<min1(1,r)
                min1(1,r)=temp;
            end
        end
    end
    %data normalized
    for r=1:nn
        for s=1:len
           ss(r,s)=(0.1*(max1(1,s)-ss(r,s))+0.9*(ss(r,s)-min1(1,s)))/(max1(1,s)-min1(1,s));
        end
    end
    %prediction on typhoon case for the next 20 steps
    %rolling forecasting method
    clear y4;
    clear input3;
    y4(:,1:len)=ss(1:end-1,:);
    y4(:,len+1:2*len)=ss(2:end,:);
    result1=zeros(m*len,nn-1);
    result1(1:len,:)=sim(net1,y4');
    input3(1:2*len,:)=y4';
    if m>1
        for r=2:m
            input3(len*i+1:len*(i+1),:)=result1(len*(r-2)+1:len*(r-1),:);
            result1(len*(r-1)+1:len*r,:)=sim(net1,input3(len*(i-1)+1:len*(i+1),:));
        end
    end
    %data inverse normalized
    for r=1:nn-1
        for s=1:len
            y4(r,s)=(y4(r,s)*(max1(1,s)-min1(1,s))+0.9*min1(1,s)-0.1*max1(1,s))/0.8;
            y4(r,s+len)=(y4(r,s+len)*(max1(1,s)-min1(1,s))+0.9*min1(1,s)-0.1*max1(1,s))/0.8;
        end
    end
    for r=1:nn
        for s=1:len
            ss(r,s)=(ss(r,s)*(max1(1,s)-min1(1,s))+0.9*min1(1,s)-0.1*max1(1,s))/0.8;
        end
    end
    for r=1:m
        for s=1:len
            for t=1:nn-1
                result1(len*(r-1)+s,t)=(result1(len*(r-1)+s,t)*(max1(1,s)-min1(1,s))+0.9*min1(1,s)-0.1*max1(1,s))/0.8;
            end
        end
    end
    %evaluation indicators calculated
    for r=1:m
        measure1(r,6*i+1)=mae(abs(ss(r+2:end,1)-result1(1+len*(r-1),1:end-r)'));
        measure1(r,6*i+2)=mse(ss(r+2:end,1),result1(1+len*(r-1),1:end-r)');
        measure1(r,6*i+3)=sqrt(mse(ss(r+2:end,1),result1(1+len*(r-1),1:end-r)'));
        measure1(r,6*i+4)=mae(abs(ss(r+2:end,2)-result1(2+len*(r-1),1:end-r)'));
        measure1(r,6*i+5)=mse(ss(r+2:end,2),result1(2+len*(r-1),1:end-r)');
        measure1(r,6*i+6)=sqrt(mse(ss(r+2:end,2),result1(2+len*(r-1),1:end-r)'));
    end
    %save the prediction values and evaluation indicators
    clear temdata5;
    clear temdata6;
    name1=strcat('bp514',num2str(number(i)),'1.xlsx');
    name2=strcat('bp514',num2str(number(i)),'0.xlsx');
    tempdata5=xlsread(name1);
    tempdata6=xlsread(name2);
    clear size;
    n21=size(tempdata5,2);
    n31=size(tempdata6,1);
    clear size;
    n22=size(result1,1);
    n32=size(measure1,2);
    temdata5(:,1:n21)=tempdata5;
    temdata5(:,n21+1:n21+n22)=result1';
    temdata6(1:n31,:)=tempdata6;
    temdata6(n31+1:n31+n32,:)=measure1;
    xlswrite(name1,temdata5);
    xlswrite(name2,temdata6);
end
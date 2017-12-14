figure(11);
clf;
peakValues

for tp=1:25
for k=1:70
    A=HDR_Data(:,:,tp,k);
    [peakV,ind]=max(A(:));
    [y,x]=ind2sub(size(A),ind);
    mask = ones(size(A))>0;
    mask(A<7000)=0;
    mask(y-5:y+5,x-5:x+5)=0;
    background_level(tp,k) = mean(A(mask));
    EF(tp,k)=peakV/background_level(tp,k);
end
end


%% Bin measurement into temperature bins...
tempDataRes=tempData(1:46);
tempRange = 22:45;
[temp_bin,ind]=histc(tempDataRes,tempRange);
for k=1:length(tempRange)
    ii=find(ind == k);
    ef_values = EF(:,ii);
    avg_tmp(k) = mean(tempDataRes(ii));
    avg_ef(k) = mean(ef_values(:));
    std_ef(k) = std(ef_values (:));
end
figure(13);
clf;hold on;
bar(avg_tmp,avg_ef,'facecolor',[0.5 0.2 0.2]);
plot(avg_tmp,std_ef+avg_ef,'k--');


s = std(EF(:,1:46))/sqrt(size(EF,1));

figure(13);
clf;hold on;
plot(tempData(1:46),mean(EF(:,1:46),1))
plot(tempData(1:46),s+mean(EF(:,1:46),1),'k--')
plot(tempData(1:46),mean(EF(:,1:46),1)-s,'k--')


%%

figure(11);
clf;hold on;
first=15;
last=45;

Mef = mean(EF(:,first:last),1);
Sef = std(EF(:,first:last),1);
plot(tempData(first:last),Mef+Sef,'k--');
plot(tempData(first:last),Mef,'k');
plot(tempData(first:last),Mef-Sef,'k--');
set(gca,'xlim',[tempData(first),tempData(last)]);
%%
figure(13);
clf;
plot(tempData(1:70),mean(EF,1))


figure(11);
clf;
imagesc(1:25,tempData(1:70),EF)
figure;
plot(tempData(1:70),log10(peakValues'))
%%
figure(13);
clf;
M=mean(peakValues,1);
S=std(peakValues,1);
Mb = mean(background_level,1);
Sb = std(background_level,1);
hold on;
t=(timeValues(1:70)-timeValues(1))/60;
plot(t,log10(M+S),'k--');
plot(t,log10(M));
plot(t,log10(M-S),'k--');

plot(t,log10(Mb),'b');
plot(t,log10(Mb+Sb),'k--');
plot(t,log10(Mb-Sb),'k--');
xlabel('Time');
set(gca,'xlim',[0 t(end)]);
p=get(13,'position');
figure(14);
set(14,'position',p);
plot(t,tempData);
set(gca,'xlim',[0 t(end)]);
box off

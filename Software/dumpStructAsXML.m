function dumpStructAsXML(strctParams,xmlFileName)
docNode = com.mathworks.xml.XMLUtils.createDocument('root_element');
docRootNode = docNode.getDocumentElement;
FieldNames = fieldnames(strctParams);
for k=1:length(FieldNames)
    if ischar(strctParams.(FieldNames{k}))
        docRootNode.setAttribute(FieldNames{k}, (strctParams.(FieldNames{k})));
    else
        docRootNode.setAttribute(FieldNames{k}, num2str(strctParams.(FieldNames{k})));
    end
end
% 
% for i=1:20
%     thisElement = docNode.createElement('child_node'); 
%     thisElement.appendChild... 
%         (docNode.createTextNode(sprintf('%i',i)));
%     docRootNode.appendChild(thisElement);
% end
% docNode.appendChild(docNode.createComment('this is a comment'));

%xmlFileName = 'C:/Users/shayo_000/Dropbox (MIT)/Code/Waveform Reshaping code/MEX/x64/Text.xml'
xmlwrite(xmlFileName,docNode);
%type(xmlFileName);
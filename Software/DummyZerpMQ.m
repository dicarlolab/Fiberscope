hSocket = ZeroMQwrapper('StartConnectThread','19.24.24.24:5002');
ZeroMQwrapper('Send',hSocket,'ClearDesign');
ZeroMQwrapper('Send',hSocket,'NewDesign Orientations');
ZeroMQwrapper('Send',hSocket,'AddCondition Name Up TrialTypes 1');
ZeroMQwrapper('Send',hSocket,'AddCondition Name Down TrialTypes 2');
ZeroMQwrapper('Send',hSocket,'AddCondition Name Left TrialTypes 3');
ZeroMQwrapper('Send',hSocket,'AddCondition Name Right TrialTypes 4');
ZeroMQwrapper('Send',hSocket,'AddCondition Name TopRight TrialTypes 5');
ZeroMQwrapper('Send',hSocket,'AddCondition Name TopLeft TrialTypes 6');
ZeroMQwrapper('Send',hSocket,'AddCondition Name BottomRight TrialTypes 7');
ZeroMQwrapper('Send',hSocket,'AddCondition Name BottomLeft TrialTypes 8');
ZeroMQwrapper('Send',hSocket,'TrialStart 1');
ZeroMQwrapper('Send',hSocket,'TrialEnd');

  
ZeroMQwrapper('CloseThread',hSocket);



public class ProcessMassLeadConversion {
    public List<MassConvertDatabaseResult> resultlist {get; set;}
    
    public ProcessMassLeadConversion(){
        resultlist = new List<MassConvertDatabaseResult>();
    }
    
    public List<MassConvertDatabaseResult> MassConvertLeads(List<MassLeadConverterController.ConversionWrapper> ConversionWrapperList){
        List<Database.LeadConvert> convertlist = new List<Database.LeadConvert>();
        List<String> leadInfoList = new List<String>();

        for(MassLeadConverterController.ConversionWrapper indConversionWrapper:ConversionWrapperList){
            Database.LeadConvert lc = new database.LeadConvert();

            lc.setLeadId(Id.valueOf(indConversionWrapper.getStringLeadId()));
            
            Id conversionAcctId;

            if(indConversionWrapper.isExistingAccount()==false){
                /* This element is to create the Account to convert to in the event there is no existing account chosen in the MassLeadConverter Controller */
                Account createAccount = new Account(Name = indConversionWrapper.getAccountName(),Type = 'Prospect');
                insert createAccount;
                conversionAcctId = createAccount.id; 
                
            }else{
                conversionAcctId = indConversionWrapper.getSelectedAccountId();
            }
            lc.setAccountId(conversionAcctId);
            
            if(indConversionWrapper.isExistingContact()==true){
                lc.setContactId(Id.valueOf(indConversionWrapper.getselectedContactId()));
            }
            
            lc.setConvertedStatus(indConversionWrapper.getselectedConvertedStatus());
            
            lc.setOwnerId(indConversionWrapper.getOwnerId());
            
            lc.setDoNotCreateOpportunity(true);

            if(indConversionWrapper.getdoNotCreateOpportunity()==False){
                lc.setDoNotCreateOpportunity(false);
                lc.setOpportunityName(indConversionWrapper.getOpportunityName());
            }
            if(indConversionWrapper.getTaskCreate() == true){
                Task taskcreate = indConversionWrapper.getTask();
                insert taskcreate;
            }
            
            convertlist.add(lc);
            /*leadInfoList is meant to hold the Lead name and Company name for context - the values are displayed on the Visualforce Page MassConvertVFPClone_Step_2 after conversion */
            leadInfoList.add(indConversionWrapper.getLeadName()+ '  -  ' + indConversionWrapper.getLeadCompanyName());
        }
        
        Database.LeadConvertResult[] conversionresult = Database.convertLead(convertlist,false);
        
        for(Integer listidx=0;listidx<conversionresult.size();listidx++){
            MassConvertDatabaseResult massconvertresult = new MassConvertDatabaseResult(conversionresult[listidx], leadInfoList[listidx]);
            this.resultlist.add(massconvertresult);
        }
        
        return this.resultlist;        
    }
}
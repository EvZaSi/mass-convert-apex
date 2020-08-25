public class MassLeadConverterController {
    public List<ConversionWrapper> listConvertParameters {get; set;}
    public List<ConversionWrapper> listConvertParametersStoreOriginal {get; set;}
    public List<MassConvertDatabaseResult> getLstResult {get; set;}
    public String selectedLeadId {get; set;}
    public String lookUpID {get; set;}
    public String lookUpLabel {get; set;}
    public String storeURL;
    public Integer successRecordCounter {get; set;}
    public Integer failureRecordCounter {get; set;}
    public Integer listsize {get; set;}
    
    public MassLeadConverterController(){
        this.getLstResult = new List<MassConvertDatabaseResult>();
        this.successRecordCounter = 0;
        this.failureRecordCounter = 0;
        this.parseURLforRecordIDs();
    }
    private void parseURLforRecordIDs(){
        String parsestring  = ApexPages.CurrentPage().getparameters().get('selectedRecords');
        if(parsestring == null){
            listsize = 0;
            return;
        }
        List<String> recordIdStringList = parsestring.split(',');
        this.listConvertParameters = new List<ConversionWrapper>(); 
        for(String leadrecordIdString:recordIdStringList){
            Id idstring = Id.valueOf(leadrecordIdString);
            List<Lead> leadQuery = [select Id,Name,Company,Owner.ID from Lead where Id = :idstring];
            ConversionWrapper createConversionWrapper = New ConversionWrapper(leadQuery[0]);
            this.listConvertParameters.add(createConversionWrapper);          
        }
        this.listsize = this.listConvertParameters.size();
    }
    public PageReference cancel(){
        PageReference originalpage;
        String parseURL  = ApexPages.CurrentPage().getparameters().get('retURL');
        if(parseURL != null){
            originalpage = new PageReference(parseURL);
            originalpage.setRedirect(True);
        }else{
            originalpage = new PageReference('/00Q/o');
            originalpage.setRedirect(True);
        }
        return originalpage;

    }
    public PageReference step1(){
        this.listConvertParameters = this.listConvertParametersStoreOriginal;
        PageReference step1VFP = new PageReference(this.storeURL);
        return step1VFP;
    }
    public pageReference chooseContact(){
        this.storeURL = ApexPages.CurrentPage().geturl();
        this.createConversionList();
        PageReference page2 = Page.MassConvertVFPClone_Step2;
        page2.setRedirect(False);
        return page2;               
    }
    public void createConversionList(){
        /* This function creates a clone of the original ConversionWrapper list, removes the ConversionWrappers that were not checked
         * by the user, and adds Contacts to the select options lists for those at existing accounts
         * where there are Contacts with the same name. */
        this.listConvertParametersStoreOriginal = new List<ConversionWrapper>();
        List<ConversionWrapper> convertList = new List<ConversionWrapper>();
        for(ConversionWrapper indConversionWrapper:this.listConvertParameters){
            this.listConvertParametersStoreOriginal.add(indConversionWrapper.cloneConversionWrapper());
            if(indConversionWrapper.leadStatus==True){
                indConversionWrapper.addContactOptions();
                convertList.add(indConversionWrapper);
                }
            }
        this.listConvertParameters = convertList;
        this.listsize = this.listConvertParameters.size();
            
    }
    public void massConvertRecords(){
        /* This function pushes the prepped conversion list to the ProcessMassLeadConversion class for
         * handling the lead conversion DML and returning the result logs. */
        for(ConversionWrapper ind_ConversionWrapper:this.listConvertParameters){
            ind_ConversionWrapper.verifyExistingContactId();
            ind_ConversionWrapper.checkTaskCreate();
        }
        ProcessMassLeadConversion processor = new ProcessMassLeadConversion();
        this.getLstResult = processor.MassConvertLeads(listConvertParameters);
        for(MassConvertDatabaseResult result:this.getLstResult){
            if(result.getresultMessage() == 'Converted Succesfully'){
                successRecordCounter += 1;
            }else{
                failureRecordCounter += 1;
            }     
        } 
    }    
    public void addAccount(){
        /* This function is used to add Accounts as options to the Account select options list
         * from the pop-out lookup menu on the Visualforce Page. */
        for(ConversionWrapper iterateConversionWrapper:this.listConvertParameters){
            if(this.selectedLeadId == iterateConversionWrapper.getStringLeadId()){
                List<Account> lookupAcctQuery = [select Id,Name from Account where Id = :lookUpID limit 1];
                wrapAccount lookupwrapAccount = new wrapAccount(lookupAcctQuery[0].Name,lookupAcctQuery[0].Id);
                SelectOption lookupAcctOption = new SelectOption(lookupwrapAccount.getAccountName(),lookupwrapAccount.generateSelectOptionLabel());
                iterateConversionWrapper.addSelectOption(lookupAcctOption,iterateConversionWrapper.listAccount);
                iterateConversionWrapper.addToWrapAccountList(lookupwrapAccount);
                break;
            }
        }
    }
    /* The wrapAccount and wrapContact classes below were created to hold both the name and ID 
     * of either an Account or Contact - the reason being is to keep SOQL queries lower by not having to
     * requery the database with the selected Contact or Account name from the Visualforce page */
    private class wrapAccount{
        String name;
        Id accountid;
        public wrapAccount(String accountName){
            this.name = accountName;
            this.accountid = null;
        }
        public wrapAccount(String accountName,Id assignedacctid){
            this.name = accountName;
            this.accountid = assignedacctid;
        }
        public String getAccountName(){
            return this.name;
        }
        public String generateSelectOptionLabel(){
            String returnlabel;
            
            if(accountid==null){
                returnlabel = 'Create New:' + this.name;
            }else{
                returnlabel = 'Use Existing:' + this.name;
            }
            return returnlabel;
        }
    }
    private class wrapContact{
        String name;
        Id contactid;
        public wrapContact(String contactName){
            this.name = contactName;
            this.contactid = null;
        }
        public wrapContact(String contactName,Id assignedcontid){
            this.name = contactName;
            this.contactid = assignedcontid;
        }
        public String getContactName(){
            return this.name;
        }
        public String generateSelectOptionLabel(){
            String returnlabel;
            
            if(contactid==null){
                returnlabel = 'Create New Contact:' + this.name;
            }else{
                returnlabel = 'Attach To Existing:' + this.name;
            }
            return returnlabel;
        }
    }
    public class ConversionWrapper {
        public Lead lead {get; set;}
        public Task task;
        public String selectedAccountName {get; set;}
        public String selectedContactName {get; set;}
        public String contactName {get; set;}
        public String opportunityName;
        public String selectedConvertedStatus;
        public String accountName;
        public Boolean leadStatus {get; set;}
        public Boolean taskcreate;
        public Boolean doNotCreateOpportunity;
        public Boolean existingAccount;
        public Boolean existingContact;
        public Id selectedAccountId;
        public Id selectedContactId;
        public List<SelectOption> listAccount {get; set;}
        public List<SelectOption> listConvertedStatus {get; set;}
        public List<SelectOption> listContact {get; set;}
        public List<wrapAccount> wrapAccountList;
        public List<wrapContact> wrapContactList;
            
        public ConversionWrapper(Lead selectedLead){
            this.lead = selectedLead;
            this.task = new Task(WhoId=selectedLead.Id);
            this.taskcreate = True;
            this.leadStatus = True;
            this.doNotCreateOpportunity = True;
            this.opportunityName = this.lead.Company + '-';
            this.selectedConvertedStatus = 'Closed - Qualified';
            this.existingAccount = False;            
            this.createConvertedStatusSelectOptionsList();
            this.createContactSelectOptionsList();           
            this.createAccountSelectOptionsList();
            
        }
        /* The next three functions all construct the Select Option lists used by the Apex:selectOption components
         * on the Visualforce pages */
        private void createConvertedStatusSelectOptionsList(){
            SelectOption originalselectedConvertedStatus = new SelectOption(selectedConvertedStatus,selectedConvertedStatus);
            this.listConvertedStatus = new List<SelectOption>();
            this.addSelectOption(originalselectedConvertedStatus,listConvertedStatus);            
        }
        private void createContactSelectOptionsList(){
            this.listContact = new List<SelectOption>();
            wrapContact originalCont;
            wrapContactList = new List<wrapContact>();
            originalCont = new wrapContact(this.lead.Name);
            this.selectedContactName = originalCont.getContactName();
            this.addToWrapContactList(originalCont);
            SelectOption originalContOption = new SelectOption(originalCont.getContactName(),originalCont.generateSelectOptionLabel());
            this.addSelectOption(originalContOption,this.listContact);
            
        }
        private void createAccountSelectOptionsList(){
            List<Account> acctquery = [select Id,Name from Account where Name = :lead.Company limit 1];
            this.listAccount = new List<SelectOption>();
            wrapAccount originalAcct;
            wrapAccountList = new List<wrapAccount>();   
            originalAcct = new wrapAccount(lead.Company);
            this.selectedAccountName = originalAcct.getAccountName();
            this.addToWrapAccountList(originalAcct);
            SelectOption originalAcctOption = new SelectOption(originalAcct.getAccountName(),originalAcct.generateSelectOptionLabel());
            this.addSelectOption(originalAcctOption,this.listAccount);
            if(acctquery.size() > 0){
                wrapAccount matchedAcct = new wrapAccount(acctquery[0].Name,acctquery[0].id);
                this.selectedAccountName = matchedAcct.getAccountName();
                this.addToWrapAccountList(matchedAcct);
                SelectOption matchedAcctOption = new SelectOption(matchedAcct.getAccountName(),matchedAcct.generateSelectOptionLabel());
                this.addSelectOption(matchedAcctOption,this.listAccount);
            }
            
        }
        public Id getOwnerId(){
            return this.lead.ownerId;
        }
        public String getLeadCompanyName(){
            return this.lead.Company;
        }
        public String getLeadName(){
            return this.lead.Name;
        }
        public Task getTask(){
            return this.task;
        }
        public String getAccountName(){
            return this.accountName;
        }
        public String getStringLeadId(){
            return String.valueOf(this.lead.Id);
        }
        public Boolean getTaskCreate(){
            return this.taskcreate;
        }
        public String getOpportunityName(){
            return this.opportunityName;
        }
        public void setOpportunityName(String newOpportunityName){
            this.opportunityName = newOpportunityName;
        }
        public Boolean getdoNotCreateOpportunity(){
            return this.doNotCreateOpportunity;
        }
        public void setdoNotCreateOpportunity(Boolean newdoNotCreateOpportunity){
            this.doNotCreateOpportunity = newdoNotCreateOpportunity;
        }
        public String getselectedConvertedStatus(){
            return this.selectedConvertedStatus;
        }
        public void setselectedConvertedStatus(String newSelectedConvertedStatus){
            this.selectedConvertedStatus = newSelectedConvertedStatus;
        }
        public Id getselectedAccountId(){
            return this.selectedAccountId;
        }
        public void setSelectedAccountId(Id newAccountId){
            this.selectedAccountId = newAccountId;
        }
        public Id getselectedContactId(){
            return this.selectedContactId;
        }
        public void setSelectedContactId(Id newContactId){
            this.selectedContactId = newContactId;
        }
        public Boolean isExistingAccount(){
            return this.existingAccount;
        }
        public Boolean isExistingContact(){
            return this.existingContact;
        }
        public void verifyExistingContactId(){
            for(wrapContact indwrapcontact:this.wrapContactList){
                if(indwrapcontact.getContactName()==this.selectedContactName && indwrapcontact.contactid != null){
                    this.existingContact = True;
                    this.selectedContactId = indwrapcontact.contactid;
                    this.contactName = indwrapcontact.getContactName();
                }else{
                    this.contactName = this.selectedContactName;
                }
            }
        }
        public void addContactOptions(){
            /* In the event the user selects an existing account, this function adds the Contact selection options
             * of any Contacts at the account with the same name. */
            for(wrapAccount indwrapaccount:this.wrapAccountList){
                if(indwrapaccount.getAccountName()==this.selectedAccountName && indwrapaccount.accountid != null){
                    this.existingAccount = True;
                    this.selectedAccountId = indwrapaccount.accountid;
                    this.accountName = indwrapaccount.getAccountName();
                }else{
                    this.accountName = this.selectedAccountName;
                }
            }
            if(existingAccount == True){
                List<Contact> contquery = [select Id,Name from Contact where ((Name = :this.lead.Name) and (AccountId = :this.selectedAccountId))];
                if(contquery.size() > 0){
                    for(Contact resultcontact:contquery){
                        wrapContact matchedCont = new wrapContact(resultcontact.Name,resultcontact.id);
                        this.selectedContactName = matchedCont.getContactName();
                        this.addToWrapContactList(matchedCont);
                        SelectOption matchedContOption = new SelectOption(matchedCont.getContactName(),matchedCont.generateSelectOptionLabel());
                        this.addSelectOption(matchedContOption,this.listContact);
                    }
                }
            }this.contactName = this.selectedContactName;
        }
        public void checkTaskCreate(){
            if(this.task.Subject == null && this.task.ActivityDate == null){
                this.taskcreate = False;
            }
        }
        public void addSelectOption(SelectOption insertSelection,List<SelectOption> selectionListVariable){
            if(selectionListVariable == this.listAccount){
                this.listAccount.add(insertSelection);
            }else if(selectionListVariable == this.listConvertedStatus){
                this.listConvertedStatus.add(insertSelection);
            }else{
                this.listContact.add(insertSelection);
            }  
        }
        public void addToWrapContactList(wrapContact newwrapcontact){
            this.wrapContactList.add(newwrapcontact);
        }
        public void addToWrapAccountList(wrapAccount newwrapaccount){
            this.wrapAccountList.add(newwrapaccount);
        }
        public ConversionWrapper cloneConversionWrapper(){
            /* Since Apex has no function to clone a non-SObject, this function is to create a ConversionWrapper with
             * the values prior to moving to the 2nd Visualforce page */
            ConversionWrapper cloneConversionWrapper = new ConversionWrapper(lead);
            cloneConversionWrapper.task = this.task;
            cloneConversionWrapper.taskcreate = this.taskcreate;
            cloneConversionWrapper.leadStatus = this.leadStatus;
            cloneConversionWrapper.doNotCreateOpportunity = this.doNotCreateOpportunity;
            cloneConversionWrapper.opportunityName = this.opportunityName;
            cloneConversionWrapper.selectedConvertedStatus = this.selectedConvertedStatus;
            cloneConversionWrapper.existingAccount = this.existingAccount;
            cloneConversionWrapper.existingContact = this.existingContact;
            cloneConversionWrapper.selectedAccountId = this.selectedAccountId;
            cloneConversionWrapper.selectedContactId = this.selectedContactId;
            cloneConversionWrapper.selectedAccountName = this.selectedAccountName;
            cloneConversionWrapper.selectedContactName = this.selectedContactName;
            cloneConversionWrapper.accountName = this.accountName;
            cloneConversionWrapper.contactName = this.contactName;
            cloneConversionWrapper.listAccount = this.listAccount;
            cloneConversionWrapper.listConvertedStatus = this.listConvertedStatus;
            cloneConversionWrapper.listContact = this.listContact;
            cloneConversionWrapper.wrapAccountList = this.wrapAccountList;
            cloneConversionWrapper.wrapContactList = this.wrapContactList;  
            return cloneConversionWrapper;
        }

    }
    
}
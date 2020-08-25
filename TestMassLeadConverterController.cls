@isTest
public class TestMassLeadConverterController {
    @isTest static void addAccountFromLookupMenu(){
        /* There's two purposes to this test. The primary is to add an Account to the options for Account selection prior to Lead conversion using the MassLeadConverterController method addAccount(). The second is to prove that the MassLeadConverterController class does convert the selected Lead using the flow of the chooseContact() method followed by the MassConvertRecords() method */
        User userToCreate = [Select id from user where (profile.name='System Administrator') and (IsActive = True) Limit 1];

        Lead testLead = new Lead(FirstName = 'John', LastName = 'Smith', Company = 'To Be Replaced',LeadSource = 'Advertisement',Status = 'Open - New Lead',OwnerId = userToCreate.Id);
        insert testLead;

        Account testAddAccount = new Account(Name = 'TestingAddAccountLookup',Type = 'Prospect');
        insert testAddAccount;

        String currentpageURL = '/apex/MassConvertVFPClone?selectedRecords=';
        currentpageURL += testLead.Id + '&retURL=/00Q/o';

        PageReference startingPage = new PageReference(currentpageURL);

        Test.startTest();
        Test.setCurrentPage(startingPage);
        MassLeadConverterController testController = new MassLeadConverterController();

        testController.selectedLeadId = String.valueOf(testLead.Id);
        testController.lookUpID = String.valueOf(testAddAccount.Id);

        testController.addAccount();
        testController.listConvertParameters[0].setSelectedAccountId(testAddAccount.Id);
        testController.listConvertParameters[0].selectedAccountName = 'TestingAddAccountLookup';

        testController.chooseContact();
        testController.step1();
        testController.chooseContact();
        testController.massConvertRecords();
        Test.stopTest();

        Contact queryContactAccountChange = [SELECT FirstName,Id FROM Contact Where Account.Name = 'TestingAddAccountLookup' limit 1];
        System.assertEquals('John',queryContactAccountChange.FirstName);

    }
    @isTest static void createOpportunityUponConversion(){
        /* The purpose of this test is to prove out that toggling the doNotCreateOpportunity Boolean field on the ConversionWrapper object does allow an opportunity to be created with the selected name. */
        
        User userToCreate = [Select id from user where (profile.name='System Administrator') and (IsActive = True) Limit 1];

        Lead testLead = new Lead(FirstName = 'John', LastName = 'Smith', Company = 'CreateOppOnThisCompany',LeadSource = 'Advertisement',Status = 'Open - New Lead',OwnerId = userToCreate.Id);
        insert testLead;

        String currentpageURL = '/apex/MassConvertVFPClone?selectedRecords=';

        currentpageURL += testLead.Id + '&retURL=/00Q/o';

        PageReference startingPage = new PageReference(currentpageURL);

        Test.startTest();
        Test.setCurrentPage(startingPage);
        MassLeadConverterController testController = new MassLeadConverterController();

        testController.listConvertParameters[0].setOpportunityName('ExampleOpportunity');
        testController.listConvertParameters[0].setdoNotCreateOpportunity(False);

        testController.chooseContact();
        testController.step1();
        testController.chooseContact();
        testController.massConvertRecords();
        Test.stopTest();

        Contact queryContact = [SELECT ID, FirstName FROM Contact WHERE Account.Name = 'CreateOppOnThisCompany' limit 1];
        System.assertEquals('John',queryContact.FirstName);
        Opportunity queryOpp = [SELECT Name FROM Opportunity WHERE Account.Name = 'CreateOppOnThisCompany' limit 1];
        System.assertEquals('ExampleOpportunity', queryOpp.Name);

    }
    @isTest static void forceUncommitableConversionQueueOwnership(){
        /* The purpose of this test is to force a uncomittable lead conversion and to show that the controller handles this by displaying the results of the failed attempt to convert rather than cause a Apex Developer Script Exception and crash the program. It also shows the conversion of other leads will still be successful with one DML failure. */
        
        Group queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = 'Unassigned Leads' limit 1];

        Lead testLead = new Lead(FirstName = 'John', LastName = 'Smith', Company = 'Uncomittable',LeadSource = 'Advertisement',Status = 'Open - New Lead',OwnerId = queue.Id);
        insert testLead;

        User userToCreate = [Select id from user where (profile.name='System Administrator') and (IsActive = True) Limit 1];

        Lead successLead = new Lead(FirstName = 'John', LastName = 'Smith', Company = 'Comittable',LeadSource = 'Advertisement',Status = 'Open - New Lead',OwnerId = userToCreate.Id);
        insert successLead;

        String currentpageURL = '/apex/MassConvertVFPClone?selectedRecords=';

        currentpageURL += testLead.Id + ',' + successLead.Id + '&retURL=/00Q/o';

        PageReference startingPage = new PageReference(currentpageURL);

        Test.startTest();
        Test.setCurrentPage(startingPage);
        MassLeadConverterController testController = new MassLeadConverterController();

        testController.chooseContact();
        testController.step1();
        testController.chooseContact();
        testController.massConvertRecords();

        System.assertEquals(1,testController.failureRecordCounter);
        for(MassConvertDatabaseResult databaseResult :testController.getLstResult){
            if(databaseResult.leadInfo == 'John Smith  -  Uncomittable'){
                System.assert(databaseResult.resultMessage.contains('nullDatabase.Error[getFields=(OwnerId);getMessage=Converted objects can only be owned by users.'),'No database commit error from Lead being converted with Queue ownership');
            }
        }

        Test.stopTest();

        Contact successContactQuery = [SELECT ID, FirstName FROM Contact WHERE Account.Name = 'Comittable' limit 1];
        System.assertEquals('John',successContactQuery.FirstName);

    }
    @isTest static void testPageCancellation(){
        /* The purpose of this test is to prove out that the cancel() method on the MassLeadConverterController object results in a new PageReference object being loaded with the retURL provided in the original PageReference. Unfortunately, I haven't figured out a way to do an assertion for this one just yet, so this is primarily left in the test class for coverage. */
        String currentpageURL = '/apex/MassConvertVFPClone?selectedRecords=';
        Lead genLead = new Lead();
        genLead.FirstName = 'John';
        genLead.LastName = 'Smith';
        genLead.Company = 'SampleCompany';
        insert genLead;        
        currentpageURL = currentpageURL + String.valueOf(genLead.id) + '&retURL=/00Q/o';
        PageReference startingPage = new PageReference(currentpageURL);        
        Test.startTest();
        Test.setCurrentPage(startingPage);
        MassLeadConverterController testController = new MassLeadConverterController();
        testController.cancel();
        Test.stopTest();

    }
    @isTest static void existingContactAtExistingAccount(){
        /* The purpose of this test is to show that the addContactOptions() method on the ConversionWrapper (that is called for each individual ConversionWrapper in the MassLeadConverterController.listConvertParameters attribute) results in a successful query of the Contact object when an existing Contact has the same name at an Account with the same name as the Company field on the Lead. It also shows that the Contact is merged at the end of the process when we select that existing Contact rather than a new Contact being created. */
        
        User userToCreate = [Select id from user where (profile.name='System Administrator') and (IsActive = True) Limit 1];

        Lead testLead = new Lead(FirstName = 'John', LastName = 'Smith', Company = 'ExistingAccount',LeadSource = 'Advertisement',Status = 'Open - New Lead',OwnerId = userToCreate.Id,Email ='emailtoproveconversion@gmail.com');
        insert testLead;

        Account addExistingAccount = new Account(Name = 'ExistingAccount',Type = 'Prospect');
        insert addExistingAccount;

        Contact contactToMatch = new Contact(AccountId = addExistingAccount.Id, FirstName = 'John', LastName = 'Smith');
        insert contactToMatch;

        String currentpageURL = '/apex/MassConvertVFPClone?selectedRecords=';
        currentpageURL += testLead.Id;

        PageReference startingPage = new PageReference(currentpageURL);

        Test.startTest();
        Test.setCurrentPage(startingPage);
        MassLeadConverterController testController = new MassLeadConverterController();

        testController.listConvertParameters[0].setselectedConvertedStatus('Closed - Qualified');
        testController.chooseContact();

        testController.listConvertParameters[0].setSelectedContactId(contactToMatch.Id);


        testController.massConvertRecords();
        Test.stopTest();

        Contact queryMergedConvertedContact = [SELECT Email FROM Contact Where Id = :contactToMatch.Id limit 1];
        System.assertEquals('emailtoproveconversion@gmail.com',queryMergedConvertedContact.Email);

    }
    @isTest static void noLeadsInURL(){
        /* The purpose of this test is to show that when our starting URL (passed in from an On-Click Javascript button) has no Lead IDs, the result is that the MassConverterController.listConvertParameters attribute is never constructed. This results in no leads being displayed on the MassConvertVFPClone Visualforce page. */
        String noLeadsURL = '/apex/MassConvertVFPClone?';
        PageReference startingPage = new PageReference(noLeadsURL);

        Test.startTest();
        Test.setCurrentPage(startingPage);
        MassLeadConverterController testController = new MassLeadConverterController();

        System.assertEquals(null,testController.listConvertParameters);
        Test.stopTest();

    }    
         
}
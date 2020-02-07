@isTest
private class TransactionProcessingTest {
    @TestSetup
    static void makeData(){
        List<Currency__c> currencies = new List<Currency__c>();
        currencies.add(new Currency__c(Name='C01', Ex_Rate__c=5));
        insert currencies;

        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(LastName='Contact', FirstName='Test'));
        insert contacts;

        List<Bank__c> banks = new List<Bank__c>();
        banks.add(new Bank__c(Name='Bank 01', Deposit_Interest__c=1, Debt_Interest__c=5,
                Withdrowal_Fee__c=10, Address__c='Bank Address, 1'));
        insert banks;

        List<ATM__c> atms = new List<ATM__c>();
        atms.add(new ATM__c(BankId__c=banks[0].Id, Address__c='ATM Address, 0'));
        insert atms;

        List<ATM_Box__c> atmBoxes = new List<ATM_Box__c>();
        atmBoxes.add(new ATM_Box__c(ATMId__c=atms[0].Id, CurrencyId__c=currencies[0].Id, Amount__c=2000));
        atmBoxes.add(new ATM_Box__c(ATMId__c=atms[0].Id, CurrencyId__c=currencies[0].Id, Amount__c=3000));
        insert atmBoxes;

        List<Card__c> cards = new List<Card__c>();
        cards.add(new Card__c(BankId__c=banks[0].Id,
                            ContactId__c=contacts[0].Id,
                            CurrencyId__c=currencies[0].Id,
                            Balance__c=10000,
                            Limit__c=20000,
                            Type__c='Credit'));
        cards.add(new Card__c(BankId__c=banks[0].Id,
                            ContactId__c=contacts[0].Id,
                            CurrencyId__c=currencies[0].Id,
                            Balance__c=0,
                            Limit__c=30000,
                            Type__c='Credit'));
        cards.add(new Card__c(BankId__c=banks[0].Id,
                            ContactId__c=contacts[0].Id,
                            CurrencyId__c=currencies[0].Id,
                            Balance__c=-45000,
                            Limit__c=50000,
                            Type__c='Credit'));
        cards.add(new Card__c(BankId__c=banks[0].Id,
                            ContactId__c=contacts[0].Id,
                            CurrencyId__c=currencies[0].Id,
                            Balance__c=5000,
                            Limit__c=0,
                            Type__c='Debit'));
        insert cards;
    }

    @isTest
    static void testMultipleTransactions() {
        System.debug('testMultipleTransactions() started');

        Currency__c curr = [SELECT Id FROM Currency__c WHERE Name = 'C01'];
        ATM__c atm = [SELECT Id FROM ATM__c WHERE Address__c = 'ATM Address, 0'];
        List<Card__c> cards = [SELECT Id FROM Card__c];

        List<Transaction__c> transactions = new List<Transaction__c>();

        transactions.add(new Transaction__c(ATMId__c=atm.Id,
                                            CardId__c=cards[0].Id,
                                            CurrencyId__c=curr.Id,
                                            Amount__c=100,
                                            Result__c='Processing'));
        transactions.add(new Transaction__c(ATMId__c=atm.Id,
                                            CardId__c=cards[1].Id,
                                            CurrencyId__c=curr.Id,
                                            Amount__c=200,
                                            Result__c='Processing'));

        Boolean insertionFailed = false;

        Test.startTest();
            try {
                List<Database.SaveResult> srList = Database.insert(transactions);
            } catch (DmlException e) {
                System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', e.getDmlStatusCode(0));
                insertionFailed = true;
            }
        Test.stopTest();

        System.assert(insertionFailed);

        System.debug('testMultipleTransactions() passed');
    }

    @isTest
    static void testSameBankSameCurrencyPositive() {
        System.debug('testSameBankPositive() started');

        Currency__c curr = [SELECT Id FROM Currency__c WHERE Name = 'C01'];
        ATM__c atm = [SELECT Id FROM ATM__c WHERE Address__c = 'ATM Address, 0'];
        Card__c card = [SELECT Id FROM Card__c WHERE Limit__c = 20000];

        Transaction__c trans = new Transaction__c(ATMId__c=atm.Id,
                                                CardId__c=card.Id,
                                                CurrencyId__c=curr.Id,
                                                Amount__c=100,
                                                Result__c='Processing');

        Test.startTest();

        System.assertEquals(0, [SELECT Id FROM Transaction__c].size());

        Savepoint savepoint1 = Database.setSavepoint();

        Database.SaveResult sr = Database.insert(trans);

        System.assert(sr.isSuccess());

        System.assertEquals(1, [SELECT Id FROM Transaction__c].size());
        trans = [SELECT Result__c FROM Transaction__c];
        System.assertEquals('Success', trans.Result__c);

        Database.rollback(savepoint1);

        Test.stopTest();

        System.debug('testSameBankPositive() passed');
    }

    @isTest
    static void testSameBankSameCurrencyInsufficientCardBalance() {
        System.debug('testSameBankSameCurrencyInsufficientCardBalance() started');

        Currency__c curr = [SELECT Id FROM Currency__c WHERE Name = 'C01'];
        ATM__c atm = [SELECT Id FROM ATM__c WHERE Address__c = 'ATM Address, 0'];
        Card__c card = [SELECT Id FROM Card__c WHERE Limit__c = 20000];

        Transaction__c trans = new Transaction__c(ATMId__c=atm.Id,
                                                CardId__c=card.Id,
                                                CurrencyId__c=curr.Id,
                                                Amount__c=31000,
                                                Result__c='Processing');

        Test.startTest();

        System.assertEquals(0, [SELECT Id FROM Transaction__c].size());
        
        Savepoint savepoint = Database.setSavepoint();

        Database.SaveResult sr = Database.insert(trans);

        System.assert(sr.isSuccess());

        System.assertEquals(1, [SELECT Id FROM Transaction__c].size());
        trans = [SELECT Result__c FROM Transaction__c];
        System.assertEquals('Denied: Excess of card limit', trans.Result__c);

        Database.rollback(savepoint);

        Test.stopTest();

        System.debug('testSameBankSameCurrencyInsufficientCardBalance() passed');
    }
}

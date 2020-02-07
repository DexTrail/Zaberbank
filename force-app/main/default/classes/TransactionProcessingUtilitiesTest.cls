@isTest
private class TransactionProcessingUtilitiesTest {
    @TestSetup
    static void makeData(){
        List<Currency__c> currencies = new List<Currency__c>();
        currencies.add(new Currency__c(Name='CCR', Ex_Rate__c=2));
        currencies.add(new Currency__c(Name='TCR', Ex_Rate__c=15));
        insert currencies;

        Contact cardContact = new Contact(LastName='Contact', FirstName='Test');
        insert cardContact;

        List<Bank__c> banks = new List<Bank__c>();
        banks.add(new Bank__c(Name='Test Card Bank', Deposit_Interest__c=10.0, Debt_Interest__c=25,
                Withdrowal_Fee__c=7, Address__c='Card Bank Address, 1'));
        banks.add(new Bank__c(Name='Test ATM Bank', Deposit_Interest__c=20.0, Debt_Interest__c=50,
                Withdrowal_Fee__c=17, Address__c='ATM Bank Address, 1'));
        insert banks;

        Card__c card = new Card__c(BankId__c=banks[0].Id,
                                    ContactId__c=cardContact.Id,
                                    CurrencyId__c=currencies[0].Id,
                                    Balance__c=1000,
                                    Limit__c=10000,
                                    Type__c='Credit');
        insert card;
    }

    @isTest
    static void testATMWithdrowalFees(){
        System.debug('testATMWithdrowalFees() started');

        Currency__c cardCurrency = [SELECT Id FROM Currency__c WHERE Name = 'CCR'];
        Contact cardContact = [SELECT Id FROM Contact];

        Bank__c cardBank = [SELECT Id FROM Bank__c WHERE Name = 'Test Card Bank'];
        Bank__c atmBank = [SELECT Withdrowal_Fee__c FROM Bank__c WHERE Name = 'Test ATM Bank'];

        Card__c card = [SELECT BankId__c, BankId__r.Withdrowal_Fee__c FROM Card__c WHERE Limit__c = 10000];

        Test.startTest();

        // Same bank without ATM fees

        ATM__c atm = new ATM__c(BankId__c=cardBank.Id, Address__c='ATM without fees, 1');

        insert atm;
        atm = [SELECT Withdrowal_Fee__c,
                    BankId__c,
                    BankId__r.Withdrowal_Fee__c
                FROM ATM__c
                WHERE Address__c = 'ATM without fees, 1'];

        System.assertEquals(0, TransactionProcessingUtilities.calculateFees(card, atm));

        // Different banks without ATM fees

        atm = new ATM__c(BankId__c=atmBank.Id, Address__c='ATM without fees, 2');

        insert atm;
        atm = [SELECT Withdrowal_Fee__c,
                    BankId__c,
                    BankId__r.Withdrowal_Fee__c
                FROM ATM__c
                WHERE Address__c = 'ATM without fees, 2'];

        System.assertEquals(atmBank.Withdrowal_Fee__c,
                TransactionProcessingUtilities.calculateFees(card, atm));
        
        // Same bank with ATM fees

        atm = new ATM__c(BankId__c=cardBank.Id, Address__c='ATM with fees, 1', Withdrowal_Fee__c=13);

        insert atm;
        atm = [SELECT Withdrowal_Fee__c,
                    BankId__c,
                    BankId__r.Withdrowal_Fee__c
                FROM ATM__c
                WHERE Address__c = 'ATM with fees, 1'];

        System.assertEquals(0, TransactionProcessingUtilities.calculateFees(card, atm));

        // Different banks with ATM fees

        atm = new ATM__c(BankId__c=atmBank.Id, Address__c='ATM with fees, 2', Withdrowal_Fee__c=13);
        
        insert atm;
        atm = [SELECT Withdrowal_Fee__c,
                    BankId__c,
                    BankId__r.Withdrowal_Fee__c
                FROM ATM__c
                WHERE Address__c = 'ATM with fees, 2'];

        System.assertEquals(atm.Withdrowal_Fee__c,
                TransactionProcessingUtilities.calculateFees(card, atm));
        
        Test.stopTest();
        
        System.debug('testATMWithdrowalFees() passed');
    }

    @isTest
    static void testCardCurrencyConverting() {
        System.debug('testCardCurrencyConverting() started');

        Currency__c transCurrency = [SELECT Ex_Rate__c FROM Currency__c WHERE Name = 'TCR'];
        Card__c card = [SELECT CurrencyId__c, CurrencyId__r.Ex_Rate__c FROM Card__c WHERE Limit__c = 10000];

        // Test same currencies
        System.assertEquals(1500,
                TransactionProcessingUtilities.convertCardCurrency(1500, card, card.CurrencyId__r));

        // Test different currencies
        System.assertEquals(200,
                TransactionProcessingUtilities.convertCardCurrency(1500, card, transCurrency));

        System.debug('testCardCurrencyConverting() passed');
    }

    @isTest
    static void testGetMoneyFromBoxes() {
        System.debug('testGetMoneyFromBoxes() started');

        List<ATM_BoxWrapper> atmBoxesWrapper = new List<ATM_BoxWrapper>();

        atmBoxesWrapper.add(new ATM_BoxWrapper(new ATM_Box__c(Amount__c=0)));
        atmBoxesWrapper.add(new ATM_BoxWrapper(new ATM_Box__c(Amount__c=1000)));
        atmBoxesWrapper.add(new ATM_BoxWrapper(new ATM_Box__c(Amount__c=2000)));
        atmBoxesWrapper.add(new ATM_BoxWrapper(new ATM_Box__c(Amount__c=10000)));

        List<ATM_Box__c> atmBoxesToUpdate =
                TransactionProcessingUtilities.getMoneyFromBoxes(1000, atmBoxesWrapper);

        System.assertEquals(2, atmBoxesToUpdate.size());
        
        System.assertEquals(0, atmBoxesToUpdate[0].Amount__c);
        System.assertEquals(0, atmBoxesToUpdate[1].Amount__c);

        atmBoxesToUpdate =
                TransactionProcessingUtilities.getMoneyFromBoxes(5000, atmBoxesWrapper);

        System.assertEquals(4, atmBoxesToUpdate.size());
        
        System.assertEquals(0, atmBoxesToUpdate[0].Amount__c);
        System.assertEquals(0, atmBoxesToUpdate[1].Amount__c);
        System.assertEquals(0, atmBoxesToUpdate[2].Amount__c);
        System.assertEquals(7000, atmBoxesToUpdate[3].Amount__c);

        System.debug('testGetMoneyFromBoxes() passed');
    }
}

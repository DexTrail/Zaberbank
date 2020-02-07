@isTest
private class InterestProcessorTest {
    private static Currency__c cardCurrency;
    private static Contact cardContact;
    private static Bank__c cardBank;

    @TestSetup
    static void makeData(){
        cardCurrency = new Currency__c(Name='CUR', Ex_Rate__c=5);
        insert cardCurrency;

        cardContact = new Contact(LastName='Contact', FirstName='Test');
        insert cardContact;

        cardBank = new Bank__c(Name='Test Bank', Deposit_Interest__c=10.0, Debt_Interest__c=25,
                Withdrowal_Fee__c=3, Address__c='Bank Address, 1');
        insert cardBank;
    }

    @isTest
    static void testZeroBalance() {
        System.debug('checkZeroBalance() started');

        cardBank = [SELECT Id FROM Bank__c LIMIT 1];
        cardContact = [SELECT Id FROM Contact LIMIT 1];
        cardCurrency = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();
        Decimal balance = 0;

        for(Integer i = 0; i < 100; i++) {
            cards.add(createCard(balance, null, null));
        }

        for(Integer i = 0; i < 100; i++) {
            cards.add(createCard(balance, 5, 20));
        }

        checkForNoCards();

        insert cards;

        Test.startTest();
            InterestProcessor processor = new InterestProcessor();
            Database.executeBatch(processor);
        Test.stopTest();

        for(Card__c card : cards) {
            System.assertEquals(0, card.Balance__c);
        }

        // Delete cards and verify no cards left
        delete cards;
        checkForNoCards();

        System.debug('checkZeroBalance() passed');
    }

    @isTest
    static void testPositiveBalanceBankInterest() {
        System.debug('checkPositiveBalanceBankInterest() started');

        cardBank = [SELECT Deposit_Interest__c FROM Bank__c LIMIT 1];
        cardContact = [SELECT Id FROM Contact LIMIT 1];
        cardCurrency = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();
        Decimal balance = 1000;

        for(Integer i = 0; i < 200; i++) {
            cards.add(createCard(balance, null, null));
        }

        checkForNoCards();

        insert cards;

        Test.startTest();
            InterestProcessor processor = new InterestProcessor();
            Database.executeBatch(processor);
        Test.stopTest();

        cards = [SELECT Balance__c FROM Card__c];

        Decimal targetBalance = balance * (1 + cardBank.Deposit_Interest__c / 100);
        for(Card__c card : cards) {
            System.assertEquals(targetBalance, card.Balance__c);
        }

        // Delete cards and verify no cards left
        delete cards;
        checkForNoCards();

        System.debug('checkPositiveBalanceBankInterest() passed');
    }

    @isTest
    static void testNegativeBalanceBankInterest() {
        System.debug('checkNegativeBalanceBankInterest() started');

        cardBank = [SELECT Debt_Interest__c FROM Bank__c LIMIT 1];
        cardContact = [SELECT Id FROM Contact LIMIT 1];
        cardCurrency = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();
        Decimal balance = -1000;

        for(Integer i = 0; i < 200; i++) {
            cards.add(createCard(balance, null, null));
        }

        checkForNoCards();

        insert cards;

        Test.startTest();
            InterestProcessor processor = new InterestProcessor();
            Database.executeBatch(processor);
        Test.stopTest();

        cards = [SELECT Balance__c FROM Card__c];

        Decimal targetBalance = balance * (1 + cardBank.Debt_Interest__c / 100);
        for(Card__c card : cards) {
            System.assertEquals(targetBalance, card.Balance__c);
        }

        // Delete cards and verify no cards left
        delete cards;
        checkForNoCards();

        System.debug('checkNegativeBalanceBankInterest() passed');
    }

    @isTest
    static void testPositiveBalanceCardInterest() {
        System.debug('checkPositiveBalanceCardInterest() started');

        cardBank = [SELECT Id FROM Bank__c LIMIT 1];
        cardContact = [SELECT Id FROM Contact LIMIT 1];
        cardCurrency = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();
        Decimal balance = 1000;

        for(Integer i = 0; i < 200; i++) {
            cards.add(createCard(balance, 5, 20));
        }

        checkForNoCards();

        insert cards;

        Test.startTest();
            InterestProcessor processor = new InterestProcessor();
            Database.executeBatch(processor);
        Test.stopTest();

        cards = [SELECT Balance__c FROM Card__c];

        Decimal targetBalance = balance * (1 + 5.0 / 100);
        for(Card__c card : cards) {
            System.assertEquals(targetBalance, card.Balance__c);
        }

        // Delete cards and verify no cards left
        delete cards;
        checkForNoCards();

        System.debug('checkPositiveBalanceCardInterest() passed');
    }

    @isTest
    static void testNegativeBalanceCardInterest() {
        System.debug('checkNegativeBalanceCardInterest() started');

        cardBank = [SELECT Id FROM Bank__c LIMIT 1];
        cardContact = [SELECT Id FROM Contact LIMIT 1];
        cardCurrency = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();
        Decimal balance = -1000;

        for(Integer i = 0; i < 200; i++) {
            cards.add(createCard(balance, 5, 20));
        }

        checkForNoCards();

        insert cards;

        Test.startTest();
            InterestProcessor processor = new InterestProcessor();
            Database.executeBatch(processor);
        Test.stopTest();

        cards = [SELECT Balance__c FROM Card__c];

        Decimal targetBalance = balance * (1 + 20.0 / 100);
        for(Card__c card : cards) {
            System.assertEquals(targetBalance, card.Balance__c);
        }

        // Delete cards and verify no cards left
        delete cards;
        checkForNoCards();

        System.debug('checkNegativeBalanceCardInterest() passed');
    }

    private static void checkForNoCards() {
        System.assertEquals(0, [SELECT Id FROM Card__c].size());
    }

    private static Card__c createCard(Decimal balance, Decimal deposit_interest, Decimal debt_interest) {
        return new Card__c(BankId__c=cardBank.Id,
                        ContactId__c=cardContact.Id,
                        CurrencyId__c=cardCurrency.Id,
                        Balance__c=balance,
                        Limit__c=2000,
                        Type__c='Credit',
                        Deposit_Interest__c=deposit_interest,
                        Debt_Interest__c=debt_interest);
    }
}

@isTest
private class CardCreationTest {
    @TestSetup
    static void makeData(){
        List<Currency__c> currencies = new List<Currency__c>();
        currencies.add(new Currency__c(Name='C01', Ex_Rate__c=.33));
        insert currencies;

        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(LastName='Contact', FirstName='Test'));
        insert contacts;

        List<Bank__c> banks = new List<Bank__c>();
        banks.add(new Bank__c(Name='Bank 01', Deposit_Interest__c=1.0, Debt_Interest__c=5,
                Withdrowal_Fee__c=10, Address__c='Some Address, 1'));
        insert banks;
    }

    @isTest
    static void singleCardTest() {
        System.debug('singleCardTest() started');

        Bank__c bank = [SELECT Id FROM Bank__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Currency__c curr = [SELECT Id FROM Currency__c LIMIT 1];

        Card__c card = new Card__c(BankId__c=bank.Id,
                                ContactId__c=contact.Id,
                                CurrencyId__c=curr.Id,
                                Balance__c=1000000,
                                Limit__c=10000000,
                                Type__c='Credit');

        System.assert(card.Id == null);
        insert card;
        System.assert(card.Id != null);

        System.debug('singleCardTest() passed');
    }

    @isTest
    static void multipleCardTest() {
        System.debug('multipleCardTest() started');

        Bank__c bank = [SELECT Id FROM Bank__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Currency__c curr = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();

        for(Integer i = 0; i < 400; i++) {
            cards.add(new Card__c(BankId__c=bank.Id,
                                        ContactId__c=contact.Id,
                                        CurrencyId__c=curr.Id,
                                        Balance__c=i * 100,
                                        Limit__c=i * 50,
                                        Type__c='Credit'));
        }

        Test.startTest();
            Database.SaveResult[] srList = Database.insert(cards);
        Test.stopTest();

        for(Database.SaveResult sr : srList) {
            System.assert(sr.isSuccess());
        }

        System.debug('multipleCardTest() passed');
    }

    @isTest
    static void debitCardsTest() {
        System.debug('debitCardTest() started');

        Bank__c bank = [SELECT Id FROM Bank__c LIMIT 1];
        Contact contact = [SELECT Id FROM Contact LIMIT 1];
        Currency__c curr = [SELECT Id FROM Currency__c LIMIT 1];

        List<Card__c> cards = new List<Card__c>();

        for(Integer i = 0; i < 400; i++) {
            cards.add(new Card__c(BankId__c=bank.Id,
                                        ContactId__c=contact.Id,
                                        CurrencyId__c=curr.Id,
                                        Balance__c=i * 100,
                                        Limit__c=i * 50,
                                        Type__c='Debit'));
        }

        Test.startTest();
            Database.SaveResult[] srList = Database.insert(cards);
        Test.stopTest();

        for(Database.SaveResult sr : srList) {
            System.assert(sr.isSuccess());
        }

        cards = [SELECT Limit__c FROM Card__c WHERE Type__c = 'Debit'];

        for(Card__c card : cards) {
            System.assertEquals(0, card.Limit__c);
        }

        System.debug('debitCardTest() passed');
    }
}

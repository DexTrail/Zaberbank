@isTest
private class ATMTerminalControllerTest {
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

        List<Card__c> cards = new List<Card__c>();
        cards.add(new Card__c(BankId__c=banks[0].Id,
                            ContactId__c=cardContact.Id,
                            CurrencyId__c=currencies[0].Id,
                            Balance__c=1000,
                            Limit__c=10000,
                            Type__c='Credit'));
        cards.add(new Card__c(BankId__c=banks[1].Id,
                            ContactId__c=cardContact.Id,
                            CurrencyId__c=currencies[1].Id,
                            Balance__c=2000,
                            Limit__c=0,
                            Type__c='Debit'));
        cards.add(new Card__c(BankId__c=banks[0].Id,
                            ContactId__c=cardContact.Id,
                            CurrencyId__c=currencies[1].Id,
                            PIN__c='1234',
                            Balance__c=3000,
                            Limit__c=30000,
                            Type__c='Credit'));
        insert cards;

        List<ATM__c> atms = new List<ATM__c>();
        atms.add(new ATM__c(BankId__c=banks[1].Id, Address__c='ATM Address, 1'));
        atms.add(new ATM__c(BankId__c=banks[1].Id, Address__c='ATM Address, 2'));
        atms.add(new ATM__c(BankId__c=banks[1].Id, Address__c='ATM Address, 3'));
        atms.add(new ATM__c(BankId__c=banks[1].Id, Address__c='ATM Address, 4'));
        insert atms;

        List<ATM_Box__c> atmBoxes = new List<ATM_Box__c>();
        atmBoxes.add(new ATM_Box__c(ATMId__c=atms[0].Id,
            CurrencyId__c=currencies[0].Id,
            Amount__c=1000
        ));
        atmBoxes.add(new ATM_Box__c(ATMId__c=atms[0].Id,
            CurrencyId__c=currencies[1].Id,
            Amount__c=3000
        ));
        atmBoxes.add(new ATM_Box__c(ATMId__c=atms[0].Id,
            CurrencyId__c=currencies[1].Id,
            Amount__c=2000
        ));
        insert atmBoxes;
    }

    @isTest
    static void checkPINTest() {
        Card__c card = [SELECT PIN__c FROM Card__c WHERE Limit__c = 30000];

        System.assertEquals(false, ATMTerminalController.checkPIN(card.Id, '0000'));
        System.assertEquals(true, ATMTerminalController.checkPIN(card.Id, '1234'));
    }

    @isTest
    static void getAllATMsTest() {
        System.debug('getAllATMsTest() started');

        List<ATM__c> atms = ATMTerminalController.getAllATMs();
        System.assertEquals(4, atms.size());

        System.debug('getAllATMsTest() passed');
    }

    @isTest
    static void getAllCardsTest() {
        System.debug('getAllCardsTest() started');

        List<Card__c> cards = ATMTerminalController.getAllCards();
        System.assertEquals(3, cards.size());

        System.debug('getAllCardsTest() passed');
    }

    @isTest
    static void getATMCurrenciesTest() {
        System.debug('getATMCurrenciesTest() started');

        ATM__c atm = [SELECT Id FROM ATM__c WHERE Address__c='ATM Address, 1'];

        List<Currency__c> currencies = ATMTerminalController.getATMCurrencies(atm.Id);
        System.assertEquals(2, currencies.size());

        System.debug('getATMCurrenciesTest() passed');
    }

    @isTest
    static void getCardBalanceTest() {
        System.debug('getCardBalanceTest() started');

        Contact cardContact = [SELECT Id FROM Contact][0];
        Bank__c bank = [SELECT Id FROM Bank__c WHERE Name='Test Card Bank'];
        Currency__c cardCurrency = [SELECT Id FROM Currency__c WHERE Name='CCR'];

        Card__c card = new Card__c(BankId__c=bank.Id,
                                ContactId__c=cardContact.Id,
                                CurrencyId__c=cardCurrency.Id,
                                Balance__c=111,
                                Limit__c=222,
                                Type__c='Credit');

        insert card;

        System.assert(card.Id != null);

        String expected = '{ "balance": "111.00", "currency": "CCR", "exrate": "2.00000000" }';
        String result = ATMTerminalController.getCardBalance(card.Id);
        System.assertEquals(expected, result);

        System.debug('getCardBalanceTest() passed');
    }

    @isTest
    static void withdrawTest() {
        System.debug('withdrawTest() started');

        ATM__c atm = [SELECT Id FROM ATM__c WHERE Address__c='ATM Address, 1'];
        Card__c card = [SELECT Id FROM Card__c WHERE Limit__c = 10000];
        Currency__c curr = [SELECT Id FROM Currency__c WHERE Name='CCR'];

        String result = ATMTerminalController.withdraw(atm.Id, card.Id, curr.Id, 500);
        System.assertEquals('Success', result);

        result = ATMTerminalController.withdraw(atm.Id, card.Id, curr.Id, 1000);
        System.assertEquals('Denied: Excess of ATM balance', result);

        System.debug('withdrawTest() passed');
    }
}

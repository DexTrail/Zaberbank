@isTest
private class RegularInterestProcessorTest {
    // This value will never be used
    private static String CRON_EXP = '0 0 3 * * ?';

    @TestSetup
    static void makeData() {
        Currency__c cardCurrency = new Currency__c(Name='CUR', Ex_Rate__c=5);
        insert cardCurrency;

        Contact cardContact = new Contact(LastName='Contact', FirstName='Test');
        insert cardContact;

        Bank__c cardBank = new Bank__c(Name='Test Bank', Deposit_Interest__c=10.0, Debt_Interest__c=25,
                Withdrowal_Fee__c=3, Address__c='Bank Address, 1');
        insert cardBank;

        List<Card__c> cards = new List<Card__c>();
        for(Integer i = 0; i < 10; i++) {
            cards.add(new Card__c(BankId__c=cardBank.Id,
                                ContactId__c=cardContact.Id,
                                CurrencyId__c=cardCurrency.Id,
                                Balance__c=1000,
                                Limit__c=2000,
                                Type__c='Credit'));
        }
        insert cards;
    }

    @isTest
    static void testScheduledJob() {
        System.debug('testScheduledJob() started');

        Test.startTest();
            System.assertEquals(0, [SELECT COUNT() FROM CronTrigger]);

            RegularInterestProcessor processor = new RegularInterestProcessor();

            String jobId = System.schedule('ScheduledJobTest', CRON_EXP, processor);
            
            // Check if job performed already
            List<Card__c> cards = [SELECT Balance__c FROM Card__c];
            for(Card__c card : cards) {
                System.assertEquals(1000, card.Balance__c);
            }
            
            System.assertEquals(1, [SELECT COUNT() FROM CronTrigger]);

            // To execute scheduled batch
            // Otherwise it will be executed in the near future
            // and we wouldn't be able to check it
            processor.execute(null);
        Test.stopTest();

        cards = [SELECT Balance__c FROM Card__c];

        for(Card__c card : cards) {
            System.assertEquals(1100, card.Balance__c);
        }

        System.debug('testScheduledJob() passed');
    }
}

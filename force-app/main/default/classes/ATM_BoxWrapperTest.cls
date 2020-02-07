@isTest
private class ATM_BoxWrapperTest {
    @TestSetup
    static void makeData(){
        Currency__c curr = new Currency__c(Name='CUR', Ex_Rate__c=5);
        insert curr;

        Bank__c bank = new Bank__c(Name='Test Bank', Deposit_Interest__c=10.0, Debt_Interest__c=25,
                Withdrowal_Fee__c=3, Address__c='Bank Address, 1');
        insert bank;

        ATM__c atm = new ATM__c(BankId__c=bank.Id, Address__c='ATM Address, 1');
        insert atm;
    }

    @isTest
    static void testWrapper() {
        System.debug('testWrapper() started');

        Currency__c curr = [SELECT Id FROM Currency__c LIMIT 1];
        Bank__c bank = [SELECT Id FROM Bank__c LIMIT 1];
        ATM__c atm = [SELECT Id FROM ATM__c LIMIT 1];

        List<ATM_BoxWrapper> wrappers = new List<ATM_BoxWrapper>();
        ATM_Box__c atm_box;
        Decimal balance;

        for(Integer i = 0; i < 400; i++) {
            balance = Math.random() * 10000;
            atm_box = new ATM_Box__c(ATMId__c=atm.Id, CurrencyId__c=curr.Id, Amount__c=balance);
            wrappers.add(new ATM_BoxWrapper(atm_box));
        }

        ATM_BoxWrapper currentWrapper;
        ATM_BoxWrapper prevWrapper = wrappers[0];

        for(Integer i = 1; i < wrappers.size(); i++) {
            currentWrapper = wrappers[i];

            if(currentWrapper.box.Amount__c == prevWrapper.box.Amount__c) {
                System.assertEquals(0, currentWrapper.compareTo(prevWrapper));
            } else if(currentWrapper.box.Amount__c > prevWrapper.box.Amount__c) {
                System.assertEquals(1, currentWrapper.compareTo(prevWrapper));
            } else {
                System.assertEquals(-1, currentWrapper.compareTo(prevWrapper));
            }
        }

        System.debug('testWrapper() passed');
    }
}

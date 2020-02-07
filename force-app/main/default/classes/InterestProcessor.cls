global class InterestProcessor implements
        Database.Batchable<SObject>, Database.Stateful {
    global Integer accountProcessed = 0;
    global Decimal depositsAccrued = 0;
    global Decimal debtsAccrued = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
                'SELECT Balance__c, Deposit_Interest__c, Debt_Interest__c, ' +
                'BankId__r.Deposit_Interest__c, BankId__r.Debt_Interest__c ' +
                'FROM Card__c ' +
                'WHERE Balance__c != 0');
    }

    global void execute(Database.BatchableContext bc, List<Card__c> scope) {
        Decimal interest, delta;
        for(Card__c card : scope) {
            if(card.Balance__c >= 0) {
                interest = card.Deposit_Interest__c != null ? card.Deposit_Interest__c : card.BankId__r.Deposit_Interest__c;
                delta = card.Balance__c * interest / 100;
                depositsAccrued += delta;
            } else {
                interest = card.Debt_Interest__c != null ? card.Debt_Interest__c : card.BankId__r.Debt_Interest__c;
                delta = card.Balance__c * interest / 100;
                debtsAccrued -= delta;
            }

            card.Balance__c += delta;

            accountProcessed++;
        }

        update scope;
    }

    global void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT NumberOfErrors
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        System.debug('IterestProcessor has finished.');
        System.debug(accountProcessed + ' Cards processed.');
        System.debug(job.NumberOfErrors + ' errors was occured.');
        System.debug(depositsAccrued + ' total was accrued on deposits.');
        System.debug(debtsAccrued + ' total was accrued on debts.');
    }
}

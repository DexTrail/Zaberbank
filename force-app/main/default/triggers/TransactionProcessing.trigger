trigger TransactionProcessing on Transaction__c (before insert) {
    /* Декомпозиция? Не, не слышал. */

    // Multiple transactions can clash with each other and cause balance to go beyond its limits.
    // So, only one transaction must be allowed.

    if(Trigger.new.size() > 1) {
        for(Transaction__c trans : Trigger.New) {
            trans.addError('Only one transaction at a time allowed.');
        }
    }

    // Collect relative data

    Transaction__c trans = Trigger.new[0];

    Card__c card = [SELECT BankId__c,
                            CurrencyId__r.Ex_Rate__c,
                            Card_Number__c,
                            Balance__c,
                            Total_Balance__c
                    FROM Card__c
                    WHERE Id = :trans.CardId__c];

    ATM__c atm = [SELECT Withdrowal_Fee__c,
                    BankId__r.Withdrowal_Fee__c,
                    (SELECT Amount__c, CurrencyId__c FROM ATM_Boxes__r)
                FROM ATM__c
                WHERE Id = :trans.ATMId__c];

    Currency__c transCurrency = [SELECT Ex_Rate__c
                                FROM Currency__c
                                WHERE Id = :trans.CurrencyId__c];
    
    // Process transactions

    // Calculate fees
    Decimal amountWithFee =
            trans.Amount__c * (1 + TransactionProcessingUtilities.calculateFees(card, atm) / 100);
    
    // Convert Card currency to Transaction currency
    Decimal convertedAmount = TransactionProcessingUtilities.convertCardCurrency(amountWithFee,
                                                                                card,
                                                                                transCurrency);

    // Check Card total balance
    if(convertedAmount > card.Total_Balance__c) {
        trans.Result__c = 'Denied: Excess of card limit';
        System.debug('Transaction finished with: ' + trans.Result__c);
        return;
    }

    // Check ATM

    // Wrapper for sorting
    List<ATM_BoxWrapper> atmBoxesWrapper = new List<ATM_BoxWrapper>();
    Decimal atmCurrencyBalance = 0;

    for(ATM_Box__c box : atm.ATM_Boxes__r) {
        if(box.CurrencyId__c == transCurrency.Id) {
            atmBoxesWrapper.add(new ATM_BoxWrapper(box));
            atmCurrencyBalance += box.Amount__c;
        }
    }

    if(trans.Amount__c > atmCurrencyBalance) {
        trans.Result__c = 'Denied: Excess of ATM balance';
        System.debug('Transaction finished with: ' + trans.Result__c);
        return;
    }

    // Do transaction

    // Get money from Card
    card.Balance__c -= convertedAmount;

    // Get money from ATM

    // Get money from boxes with less amount first
    atmBoxesWrapper.sort();

    List<ATM_Box__c> atmBoxesToUpdate =
            TransactionProcessingUtilities.getMoneyFromBoxes(trans.Amount__c, atmBoxesWrapper);

    // Object updates

    // If any error occurs we need to rollback all updates
    Savepoint savepoint = Database.setSavepoint();
    Boolean isSucceedUpdate = True;

    // Update Card
    Database.SaveResult sr = Database.update(card);
    if(!sr.isSuccess()) {
        isSucceedUpdate = False;

        System.debug('Errors occured while updating Card:');
        System.debug('Card number:' + card.Card_Number__c);
        for(Database.Error err : sr.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Fields affected this error: ' + err.getFields());
        }
    }

    // Update ATM Boxes
    if(isSucceedUpdate) {
        Database.SaveResult[] srList = Database.update(atmBoxesToUpdate);

        for(Database.SaveResult sr : srList) {
            if(!sr.isSuccess()) {
                isSucceedUpdate = False;

                System.debug('Errors occured while updating ATM Boxes:');
                for(Database.Error err : sr.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields affected this error: ' + err.getFields());
                }
            }
        }
    }

    if(!isSucceedUpdate) {
        Database.rollback(savepoint);
        trans.Result__c = 'Denied: Error while transaction execution';
    } else {
        trans.Result__c = 'Success';
    }

    System.debug('Transaction finished with: ' + trans.Result__c);
}
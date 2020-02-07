public class ATMTerminalController {
    @AuraEnabled
    public static Boolean checkPIN(Id cardId, String pin){
        Card__c card = [SELECT PIN__c FROM Card__c WHERE Id = :cardId];

        return pin == card.PIN__c;
    }

    @AuraEnabled
    public static List<ATM__c> getAllATMs(){
        List<ATM__c> atms = new List<ATM__c>();
        atms = [SELECT Name FROM ATM__c ORDER BY Name];
        return atms;
    }

    @AuraEnabled
    public static List<Card__c> getAllCards(){
        List<Card__c> cards = new List<Card__c>();
        cards = [SELECT Card_Number__c,
                        ContactId__r.FirstName,
                        ContactId__r.LastName,
                        CurrencyId__r.Name,
                        CurrencyId__r.Ex_Rate__c
                FROM Card__c
                ORDER BY Card_Number__c];
        System.debug(cards);
        return cards;
    }

    @AuraEnabled
    public static List<Currency__c> getATMCurrencies(Id atmId){
        List<Currency__c> currencies = new List<Currency__c>();
        currencies = [SELECT Name, Ex_Rate__c
                    FROM Currency__c
                    WHERE Id IN (SELECT CurrencyId__c FROM ATM_Box__c WHERE ATMId__c = :atmId)
                    ORDER BY Name];
        return currencies;
    }

    @AuraEnabled
    public static String getCardBalance(Id cardId){
        Card__c card = [SELECT Balance__c, CurrencyId__r.Name, CurrencyId__r.Ex_Rate__c
                        FROM Card__c
                        WHERE Id = :cardId];

        String jsonString = '{ "balance": "' + card.Balance__c
                            + '", "currency": "' + card.CurrencyId__r.Name
                            + '", "exrate": "' + card.CurrencyId__r.Ex_Rate__c + '" }';
        return jsonString;
    }

    @AuraEnabled
    public static String withdraw(Id atmId, Id cardId, Id currencyId, Decimal amount){
        Transaction__c trans = new Transaction__c(ATMId__c = atmId,
                                                CardId__c = cardId,
                                                CurrencyId__c = currencyId,
                                                Amount__c = amount);

        Database.SaveResult sr = Database.insert(trans);
        trans = [SELECT Result__c FROM Transaction__c WHERE Id = :trans.Id];

        return trans.Result__c;
    }
}

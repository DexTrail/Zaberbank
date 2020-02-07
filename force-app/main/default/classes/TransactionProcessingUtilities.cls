public without sharing class TransactionProcessingUtilities {
    public static Decimal calculateFees(Card__c card, ATM__c atm) {
        Decimal fee = 0;

        if(card.BankId__c != atm.BankId__c) {
            fee = atm.Withdrowal_Fee__c != null ? atm.Withdrowal_Fee__c : atm.BankId__r.Withdrowal_Fee__c;
        }

        return fee;
    }

    public static Decimal convertCardCurrency(Decimal amount, Card__c card, Currency__c transCurrency) {
        Decimal convertedAmount;

        if(card.CurrencyId__c == transCurrency.Id) {
            convertedAmount = amount;
        } else {
            convertedAmount =
                amount * card.CurrencyId__r.Ex_Rate__c / transCurrency.Ex_Rate__c;
        }

        return convertedAmount;
    }

    public static List<ATM_Box__c> getMoneyFromBoxes(Decimal amount, List<ATM_BoxWrapper> atmBoxesWrapper) {
        List<ATM_Box__c> atmBoxesToUpdate = new List<ATM_Box__c>();

        ATM_Box__c box;
        for(ATM_BoxWrapper boxWrapper : atmBoxesWrapper) {
            if(amount <= 0) {
                break;
            }

            box = boxWrapper.box;

            if(amount <= box.Amount__c) {
                box.Amount__c -= amount;
                amount = 0;
            } else {
                amount -= box.Amount__c;
                box.Amount__c = 0;
            }

            atmBoxesToUpdate.add(box);
        }

        return atmBoxesToUpdate;
    }
}

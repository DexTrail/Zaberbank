public class ATM_BoxWrapper implements Comparable {
    public ATM_Box__c box;

    public ATM_BoxWrapper(ATM_Box__c box) {
        this.box = box;
    }

    public Integer compareTo(Object compareTo) {
        ATM_BoxWrapper compareToWrapper = (ATM_BoxWrapper)compareTo;

        Integer returnValue = 0;
        if(box.Amount__c > compareToWrapper.box.Amount__c) {
            returnValue = 1;
        } else if(box.Amount__c < compareToWrapper.box.Amount__c) {
            returnValue = -1;
        }

        return returnValue;
    }
}

global class RegularInterestProcessor implements Schedulable {
    global void execute(SchedulableContext ctx) {
        InterestProcessor processor = new InterestProcessor();
        Database.executeBatch(processor);
    }
}

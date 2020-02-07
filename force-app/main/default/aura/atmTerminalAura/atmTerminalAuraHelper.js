({
    /* Здесь и далее не говнокод. Это обфускация */
    
    checkPIN: function(component) {
        let cardID = component.find("card-selector").get("v.value");

        // If somehow cardID is empty
        if(!cardID) {
            this.clearData(component);
            return;
        }

        let pin = component.find("pin-field").get("v.value");
        component.find("pin-field").set("v.value", null);

        let action = component.get("c.checkPIN");

        action.setParams({
            "cardId": cardID,
            "pin": pin
        });

        action.setCallback(this, function(response) {
            let value;
            if(response.getState() == 'SUCCESS') {
                value = response.getReturnValue()
            } else if(response.getState() == 'ERROR') {
                alert("An ERROR occured while checking PIN.");
            }

            if(value) {
                component.set("v.selectedCard", cardID);
                component.set("v.requestPIN", false);

                // Get contact's first and last name
                let cards = component.get("v.cards");
                let firstName, lastName;
                cards.some(card => {
                    if(card["value"] === cardID) {
                        firstName = card["firstName"];
                        lastName = card["lastName"];
                        return true;
                    }
                });

                let text = `Welcome, ${firstName} ${lastName}!`;
                this.setTerminalText(component, text, 2000, "Select currency");
            } else {
                this.clearData(component);
                this.setTerminalText(component, "Incorrect PIN", 2000, "Select a card");
            }
        });

        $A.enqueueAction(action);
    },

    clearData: function(component) {
        // Clear input
        component.set("v.userInput", null);
        component.set("v.terminalTextSmall", null);

        // Clear card data
        component.find("card-selector").set("v.value", null);
        component.set("v.selectedCard", null);
        component.set("v.requestPIN", false);

        // Clear selected card currency data
        component.set("v.cardCurrencyName", null);
        component.set("v.cardCurrencyExrate", null);

        // Clear currency data
        component.find("currency-selector").set("v.value", null);
        component.set("v.selectedCurrency", null);
    },

    getBalance : function(component) {
        let action = component.get("c.getCardBalance");

        action.setParams({
            "cardId": component.get("v.selectedCard")
        });

        action.setCallback(this, function(response) {
            let returnedValues;
            if(response.getState() == 'SUCCESS') {
                let value = response.getReturnValue()
                // No longer need to return currency and exchange rate in JSON.
                // Balance is enough.
                returnedValues = JSON.parse(value);
            } else if(response.getState() == 'ERROR') {
                alert("An ERROR occured while getting balance.");
            }

            let balance = parseFloat(returnedValues["balance"]);
            balance = Math.round(balance * 100) / 100;
            let text = `Balance: ${balance} ${returnedValues["currency"]}`;
            this.setTerminalText(component, text);
        });

        $A.enqueueAction(action);
    },

    initCurrencies: function(component) {
        let action = component.get("c.getATMCurrencies");
        let currencies = [];

        action.setParams({
            "atmId": component.get("v.selectedAtm")
        });

        action.setCallback(this, function(response) {
            if(response.getState() == 'SUCCESS') {
                let allValues = response.getReturnValue();
                for(let i = 0; i < allValues.length; i++) {
                    currencies.push({
                        "label": allValues[i].Name,
                        "value": allValues[i].Id,
                        "exrate": allValues[i].Ex_Rate__c
                    });
                }
            } else if(response.getState() == 'ERROR') {
                alert("An ERROR occured while getting currencies.");
            }

            component.set("v.currencies", currencies);
        });

        $A.enqueueAction(action);
    },

    pulloutCard: function(component) {
        this.clearData(component);
        this.setTerminalText(component, "Goodbye!", 2000, "Select a card");
    },

    setCardCurrency: function(component) {
        let cards = component.get("v.cards");
        let currentCard = component.find("card-selector").get("v.value");

        cards.some(card => {
            if(card["value"] === currentCard) {
                component.set("v.cardCurrencyName", card["currencyCode"]);
                component.set("v.cardCurrencyExrate", card["exrate"]);
                return true;
            }
        });
    },

    setTerminalText: function(component, textBefore, timeout, textAfter) {
        component.set("v.terminalText", textBefore);

        if(timeout) {
            setTimeout(() => {
                    component.set("v.terminalText", textAfter);
                },
                timeout);
        }
    },

    showExRate: function(component, inputAmount) {
        if(!inputAmount) {
            inputAmount = 1;
        }

        // Get card currency data
        let cardCurrency = component.get("v.cardCurrencyName");
        let cardExrate = component.get("v.cardCurrencyExrate");

        // Get ATM currency data
        let currencies = component.get("v.currencies");
        let selectedCurrency = component.get("v.selectedCurrency");
        let atmCurrency, atmExrate;
        currencies.some(curr => {
            if(curr["value"] === selectedCurrency) {
                atmCurrency = curr["label"];
                atmExrate = curr["exrate"];
                return true;
            }
        });

        // Exchange rate calculation
        // {finalExrate} CardCurrency for 1 ATMCurrency
        let finalExrate = cardExrate / atmExrate;

        // Check for any errors (like division by 0)
        if(finalExrate) {
            // Final exchange amount calculation
            // {withdrawAmount} CardCurrency for {inputAmount} ATMCurrency
            let withdrawAmount = inputAmount * finalExrate;
            withdrawAmount = Math.round(withdrawAmount * 100) / 100;

            // Show exchange info
            let text = `Exchange rate: ${withdrawAmount} ${cardCurrency} `
                    + `for ${inputAmount} ${atmCurrency}`;
            component.set("v.terminalTextSmall", text);
        } else {
            console.log("An ERROR occured while calculating exchange rate.")
            console.log(`cardExrate = ${cardExrate}`);
            console.log(`atmExrate = ${atmExrate}`);
            
            component.set("v.terminalTextSmall", null);
        }
    },

    withdraw: function(component) {
        let action = component.get("c.withdraw");

        action.setParams({
            "atmId": component.get("v.selectedAtm"),
            "cardId": component.get("v.selectedCard"),
            "currencyId": component.get("v.selectedCurrency"),
            "amount": component.get("v.userInput")
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            let withdrawResult;

            if(state == 'SUCCESS') {
                withdrawResult = response.getReturnValue();
                this.setTerminalText(component, withdrawResult);
            } else {
                alert("An ERROR occured while trying to withdraw.\nCall ATM maintanance service.");
            }

            component.set("v.userInput", null);
            this.showExRate(component);
        });

        $A.enqueueAction(action);
    }
})

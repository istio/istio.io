"use strict";

class KbdNav {
    constructor(elements) {
        this.elements = elements;
    }

    focusFirstElement() {
        this.elements[0].focus();
    }

    focusLastElement() {
        this.elements[this.elements.length - 1].focus();
    }

    focusNextElement() {
        for (let i = 0; i < this.elements.length; i++) {
            if (this.elements[i] === document.activeElement) {
                if (i < this.elements.length - 1) {
                    this.elements[i + 1].focus();
                    return;
                }
                break;
            }
        }

        this.focusFirstElement();
    }

    focusPrevElement() {
        for (let i = 0; i < this.elements.length; i++) {
            if (this.elements[i] === document.activeElement) {
                if (i > 0) {
                    this.elements[i - 1].focus();
                    return;
                }
                break;
            }
        }

        this.focusLastElement();
    }

    focusElementByChar(ch) {

        function getIndexFirstChars(startIndex, ch, elements) {
            for (let i = startIndex; i < elements.length; i++) {
                const firstChar = elements[i].textContent.trim().substring(0, 1).toLowerCase();
                if (ch === firstChar) {
                    return i;
                }
            }
            return -1;
        }

        ch = ch.toLowerCase();
        for (let i = 0; i < this.elements.length; i++) {
            if (this.elements[i] === document.activeElement) {

                // Check remaining slots in the strip
                let index = getIndexFirstChars(i + 1, ch, this.elements);

                // If not found in remaining slots, check from beginning
                if (index === -1) {
                    index = getIndexFirstChars(0, ch, this.elements);
                }

                // If match was found...
                if (index > -1) {
                    this.elements[index].focus();
                }
                break;
            }
        }
    }
}

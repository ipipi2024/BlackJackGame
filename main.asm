.386
.model flat,stdcall
.stack 4096
INCLUDE Irvine32.inc
ExitProcess proto, dwExitCode:dword

.data
deckCounts DWORD 13 DUP(4)   ; 13 card ranks, each starts with count of 4
totalCardsDrawn DWORD 0       ; total cards drawn from deck
msgRank BYTE "Rank: ", 0
msgValue BYTE " -> Value: ", 0
currentCard DWORD ?           ; temporary storage for current card

; Hand storage (max 11 cards possible in blackjack before bust)
playerHand DWORD 11 DUP(0)    ; player's cards
playerHandSize DWORD 0        ; number of cards in player hand
dealerHand DWORD 11 DUP(0)    ; dealer's cards
dealerHandSize DWORD 0        ; number of cards in dealer hand

; Test messages
msgHand BYTE "Hand: ", 0
msgTotal BYTE " = Total: ", 0
msgSpace BYTE " ", 0

; User input messages
msgPrompt BYTE "Hit or Stand? (H/S): ", 0
msgInvalidInput BYTE "Invalid input! Please enter H or S.", 0
msgYouChose BYTE "You chose: ", 0
msgHit BYTE "Hit", 0
msgStand BYTE "Stand", 0
playerChoice BYTE ?

; Card names for display
cardAce BYTE "Ace", 0
card2 BYTE "2", 0
card3 BYTE "3", 0
card4 BYTE "4", 0
card5 BYTE "5", 0
card6 BYTE "6", 0
card7 BYTE "7", 0
card8 BYTE "8", 0
card9 BYTE "9", 0
card10 BYTE "10", 0
cardJack BYTE "Jack", 0
cardQueen BYTE "Queen", 0
cardKing BYTE "King", 0

; Game display messages
msgPlayerHand BYTE "Your hand: ", 0
msgDealerHand BYTE "Dealer shows: ", 0
msgDealerHidden BYTE "Dealer has: [Hidden Card] ", 0
msgComma BYTE ", ", 0

; Blackjack messages
msgBlackjack BYTE "BLACKJACK!", 0
msgNotBlackjack BYTE "Not a blackjack (but total is 21)", 0
msgTestBlackjack BYTE "Testing: ", 0

; Dealer messages
msgDealerReveals BYTE "Dealer reveals: ", 0
msgDealerHits BYTE "Dealer hits...", 0
msgDealerStands BYTE "Dealer stands.", 0
msgDealerTotal BYTE "Dealer's total: ", 0
msgDealerBust BYTE "Dealer busts!", 0

; Win condition messages
msgPlayerWins BYTE "*** PLAYER WINS! ***", 0
msgDealerWins BYTE "*** DEALER WINS! ***", 0
msgPush BYTE "*** PUSH (TIE) ***", 0
msgPlayerBust BYTE "Player busts!", 0
msgPlayerBlackjackWins BYTE "Player has BLACKJACK! Player wins!", 0
msgDealerBlackjackWins BYTE "Dealer has BLACKJACK! Dealer wins!", 0
msgBothBlackjack BYTE "Both have BLACKJACK! Push!", 0

; Game flow messages
msgWelcome BYTE "========================================", 0
msgTitle BYTE "       BLACKJACK GAME", 0
msgDivider BYTE "========================================", 0
msgDealing BYTE "Dealing cards...", 0
msgPlayerTurn BYTE "--- YOUR TURN ---", 0
msgDealerTurn BYTE "--- DEALER'S TURN ---", 0
msgGameOver BYTE "========== GAME OVER ==========", 0
msgNewCard BYTE "New card: ", 0

.code

;------------------------------------------
; InitializeDeck PROC
; Description: Resets the deck to initial state (4 of each rank)
; Input: None
; Output: None
; Modifies: deckCounts array, totalCardsDrawn
;------------------------------------------
InitializeDeck PROC
    push ecx
    push edi
    push eax

    ; Reset all counts to 4
    mov ecx, 13
    mov edi, OFFSET deckCounts
    mov eax, 4

resetLoop:
    mov [edi], eax
    add edi, 4
    loop resetLoop

    ; Reset total cards drawn
    mov totalCardsDrawn, 0

    pop eax
    pop edi
    pop ecx
    ret
InitializeDeck ENDP

;------------------------------------------
; DrawCard PROC
; Description: Draws a random card from the deck (1-13)
;              Automatically regenerates if selected card is exhausted
; Input: None
; Output: EAX = card rank (1-13)
; Modifies: EAX, deckCounts array
;------------------------------------------
DrawCard PROC
    push ecx
    push edi

tryAgain:
    ; Generate random number 0-12 (array index)
    mov eax, 13
    call RandomRange      ; EAX = 0-12

    ; Check if this rank is available (count > 0)
    mov ecx, eax          ; save index
    mov edi, OFFSET deckCounts
    mov eax, [edi + ecx*4] ; get deckCounts[index]
    cmp eax, 0
    je tryAgain           ; if count = 0, try another card

    ; Decrement the count for this rank
    dec eax
    mov [edi + ecx*4], eax

    ; Convert index to card rank (1-13) for return
    mov eax, ecx
    inc eax               ; convert 0-12 to 1-13

    pop edi
    pop ecx
    ret
DrawCard ENDP

;------------------------------------------
; GetCardValue PROC
; Description: Converts card rank (1-13) to blackjack value
; Input: EAX = card rank (1-13)
; Output: EAX = blackjack value
;         1 (Ace) ? 1
;         2-10 ? face value (2-10)
;         11 (Jack), 12 (Queen), 13 (King) ? 10
; Modifies: EAX only
;------------------------------------------
GetCardValue PROC
    ; If rank is 1 (Ace), return 1
    cmp eax, 1
    je aceValue

    ; If rank is 2-10, return face value
    cmp eax, 10
    jbe faceValue

    ; If rank is 11-13 (Jack, Queen, King), return 10
    mov eax, 10
    ret

aceValue:
    mov eax, 1
    ret

faceValue:
    ; EAX already contains the face value (2-10)
    ret
GetCardValue ENDP

;------------------------------------------
; GetCardName PROC
; Description: Returns a pointer to the card name string
; Input: EAX = card rank (1-13)
; Output: EDX = pointer to card name string
; Modifies: EDX only
;------------------------------------------
GetCardName PROC
    cmp eax, 1
    je isAce
    cmp eax, 2
    je is2
    cmp eax, 3
    je is3
    cmp eax, 4
    je is4
    cmp eax, 5
    je is5
    cmp eax, 6
    je is6
    cmp eax, 7
    je is7
    cmp eax, 8
    je is8
    cmp eax, 9
    je is9
    cmp eax, 10
    je is10
    cmp eax, 11
    je isJack
    cmp eax, 12
    je isQueen
    cmp eax, 13
    je isKing
    ret

isAce:
    mov edx, OFFSET cardAce
    ret
is2:
    mov edx, OFFSET card2
    ret
is3:
    mov edx, OFFSET card3
    ret
is4:
    mov edx, OFFSET card4
    ret
is5:
    mov edx, OFFSET card5
    ret
is6:
    mov edx, OFFSET card6
    ret
is7:
    mov edx, OFFSET card7
    ret
is8:
    mov edx, OFFSET card8
    ret
is9:
    mov edx, OFFSET card9
    ret
is10:
    mov edx, OFFSET card10
    ret
isJack:
    mov edx, OFFSET cardJack
    ret
isQueen:
    mov edx, OFFSET cardQueen
    ret
isKing:
    mov edx, OFFSET cardKing
    ret
GetCardName ENDP

;------------------------------------------
; CalculateHandValue PROC
; Description: Calculates the total value of a hand with Ace optimization
;              Aces are counted as 11 if it doesn't cause a bust, otherwise 1
; Input: ESI = pointer to hand array (DWORD array of card ranks)
;        ECX = hand size (number of cards)
; Output: EAX = total hand value
; Modifies: EAX, EBX, ECX, EDX
;------------------------------------------
CalculateHandValue PROC
    push esi
    push edi

    mov eax, 0            ; total = 0
    mov ebx, 0            ; aceCount = 0
    mov edi, ecx          ; save hand size

    ; If hand is empty, return 0
    cmp edi, 0
    je emptyHand

calculateLoop:
    ; Get current card rank
    mov edx, [esi]
    push eax              ; save current total
    mov eax, edx

    ; Check if it's an Ace
    cmp eax, 1
    jne notAce
    inc ebx               ; increment ace count

notAce:
    ; Convert rank to value
    call GetCardValue
    mov edx, eax          ; save card value
    pop eax               ; restore total
    add eax, edx          ; total += card value

    ; Move to next card
    add esi, 4
    dec edi
    jnz calculateLoop

    ; Now optimize Aces: if we have an Ace and total + 10 <= 21, add 10
    cmp ebx, 0            ; do we have any Aces?
    je noAceOptimization

    add eax, 10           ; try counting one Ace as 11
    cmp eax, 21
    jbe aceOptimized      ; if total <= 21, keep it
    sub eax, 10           ; otherwise, revert back

aceOptimized:
noAceOptimization:
emptyHand:
    pop edi
    pop esi
    ret
CalculateHandValue ENDP

;------------------------------------------
; IsBlackjack PROC
; Description: Checks if a hand is a natural blackjack (21 with exactly 2 cards)
; Input: ESI = pointer to hand array (DWORD array of card ranks)
;        ECX = hand size (number of cards)
; Output: EAX = 1 if blackjack, 0 otherwise
; Modifies: EAX
;------------------------------------------
IsBlackjack PROC
    push ecx
    push esi
    push ebx

    ; Check if hand has exactly 2 cards
    cmp ecx, 2
    jne notBlackjack      ; if not 2 cards, not blackjack

    ; Calculate hand value
    call CalculateHandValue
    mov ebx, eax          ; save total

    ; Check if total is 21
    cmp ebx, 21
    jne notBlackjack

    ; It's a blackjack!
    mov eax, 1
    jmp endCheck

notBlackjack:
    mov eax, 0

endCheck:
    pop ebx
    pop esi
    pop ecx
    ret
IsBlackjack ENDP

;------------------------------------------
; DealerPlay PROC
; Description: Executes dealer logic (hit on 16 or less, stand on 17+)
; Input: None (uses dealerHand and dealerHandSize)
; Output: EAX = final dealer total
; Modifies: EAX, dealerHand, dealerHandSize
;------------------------------------------
DealerPlay PROC
    push ebx
    push ecx
    push edx
    push esi

    ; Display dealer's full hand
    mov edx, OFFSET msgDealerReveals
    call WriteString
    mov esi, OFFSET dealerHand
    mov ecx, dealerHandSize
    call DisplayHand

dealerLoop:
    ; Calculate current dealer total
    mov esi, OFFSET dealerHand
    mov ecx, dealerHandSize
    call CalculateHandValue
    mov ebx, eax          ; save total in EBX

    ; Check if dealer must hit (total < 17)
    cmp ebx, 17
    jae dealerStands      ; if >= 17, dealer stands

    ; Dealer hits
    mov edx, OFFSET msgDealerHits
    call WriteString
    call Crlf

    ; Draw a card
    call DrawCard

    ; Add card to dealer hand
    mov ecx, dealerHandSize
    mov esi, OFFSET dealerHand
    shl ecx, 2            ; convert to byte offset
    add esi, ecx          ; point to next slot
    mov [esi], eax        ; store new card

    ; Increment hand size
    inc dealerHandSize

    ; Display new card
    call GetCardName
    call WriteString
    mov edx, OFFSET msgSpace
    call WriteString

    ; Show updated total
    mov esi, OFFSET dealerHand
    mov ecx, dealerHandSize
    call CalculateHandValue
    mov ebx, eax

    mov edx, OFFSET msgDealerTotal
    call WriteString
    mov eax, ebx
    call WriteDec
    call Crlf

    ; Check if dealer busted
    cmp ebx, 21
    ja dealerBusted

    ; Continue loop
    jmp dealerLoop

dealerStands:
    mov edx, OFFSET msgDealerStands
    call WriteString
    call Crlf
    mov edx, OFFSET msgDealerTotal
    call WriteString
    mov eax, ebx
    call WriteDec
    call Crlf
    jmp dealerDone

dealerBusted:
    mov edx, OFFSET msgDealerBust
    call WriteString
    call Crlf

dealerDone:
    mov eax, ebx          ; return final total

    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
DealerPlay ENDP

;------------------------------------------
; DetermineWinner PROC
; Description: Compares player and dealer hands to determine winner
; Input: None (uses playerHand, playerHandSize, dealerHand, dealerHandSize)
; Output: EAX = 0 (dealer wins), 1 (player wins), 2 (push)
; Modifies: EAX, ECX, ESI
;------------------------------------------
DetermineWinner PROC
    push ebx
    push ecx
    push edx
    push esi
    push edi

    ; Calculate player total
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    call CalculateHandValue
    mov ebx, eax              ; EBX = player total

    ; Calculate dealer total
    mov esi, OFFSET dealerHand
    mov ecx, dealerHandSize
    call CalculateHandValue
    mov edi, eax              ; EDI = dealer total

    ; Check for player blackjack
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    call IsBlackjack
    push eax                  ; save player blackjack status

    ; Check for dealer blackjack
    mov esi, OFFSET dealerHand
    mov ecx, dealerHandSize
    call IsBlackjack
    mov edx, eax              ; EDX = dealer blackjack status
    pop eax                   ; EAX = player blackjack status

    ; Check if both have blackjack
    cmp eax, 1
    jne checkDealerBJ
    cmp edx, 1
    jne playerBlackjackWins
    ; Both have blackjack
    mov edx, OFFSET msgBothBlackjack
    call WriteString
    call Crlf
    mov eax, 2                ; Push
    jmp winnerDone

playerBlackjackWins:
    mov edx, OFFSET msgPlayerBlackjackWins
    call WriteString
    call Crlf
    mov eax, 1                ; Player wins
    jmp winnerDone

checkDealerBJ:
    cmp edx, 1
    jne checkBusts
    ; Dealer has blackjack, player doesn't
    mov edx, OFFSET msgDealerBlackjackWins
    call WriteString
    call Crlf
    mov eax, 0                ; Dealer wins
    jmp winnerDone

checkBusts:
    ; Check if player busted
    cmp ebx, 21
    ja playerBusted

    ; Check if dealer busted
    cmp edi, 21
    ja dealerBusted

    ; Neither busted, compare totals
    cmp ebx, edi
    jg playerWinsNormal
    jl dealerWinsNormal

    ; Equal totals = push
    mov edx, OFFSET msgPush
    call WriteString
    call Crlf
    mov eax, 2                ; Push
    jmp winnerDone

playerBusted:
    mov edx, OFFSET msgPlayerBust
    call WriteString
    call Crlf
    mov edx, OFFSET msgDealerWins
    call WriteString
    call Crlf
    mov eax, 0                ; Dealer wins
    jmp winnerDone

dealerBusted:
    ; Dealer already printed bust message in DealerPlay
    mov edx, OFFSET msgPlayerWins
    call WriteString
    call Crlf
    mov eax, 1                ; Player wins
    jmp winnerDone

playerWinsNormal:
    mov edx, OFFSET msgPlayerWins
    call WriteString
    call Crlf
    mov eax, 1                ; Player wins
    jmp winnerDone

dealerWinsNormal:
    mov edx, OFFSET msgDealerWins
    call WriteString
    call Crlf
    mov eax, 0                ; Dealer wins

winnerDone:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
DetermineWinner ENDP

;------------------------------------------
; PlayBlackjack PROC
; Description: Main game procedure - integrates all components
; Input: None
; Output: None
; Modifies: All game state variables
;------------------------------------------
PlayBlackjack PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    ; Display welcome message
    mov edx, OFFSET msgWelcome
    call WriteString
    call Crlf
    mov edx, OFFSET msgTitle
    call WriteString
    call Crlf
    mov edx, OFFSET msgDivider
    call WriteString
    call Crlf
    call Crlf

    ; Initialize deck
    call InitializeDeck

    ; Deal initial cards
    mov edx, OFFSET msgDealing
    call WriteString
    call Crlf

    ; Player card 1
    call DrawCard
    mov playerHand[0], eax
    mov playerHandSize, 1

    ; Dealer card 1
    call DrawCard
    mov dealerHand[0], eax
    mov dealerHandSize, 1

    ; Player card 2
    call DrawCard
    mov playerHand[4], eax
    mov playerHandSize, 2

    ; Dealer card 2
    call DrawCard
    mov dealerHand[4], eax
    mov dealerHandSize, 2

    call Crlf

    ; Display initial game state
    call DisplayGameState

    ; Check for natural blackjack
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    call IsBlackjack
    mov ebx, eax              ; save player blackjack status

    mov esi, OFFSET dealerHand
    mov ecx, dealerHandSize
    call IsBlackjack
    push eax                  ; save dealer blackjack status

    ; If either has blackjack, game ends immediately
    pop eax                   ; dealer blackjack
    cmp ebx, 1
    je endGameNatural
    cmp eax, 1
    je endGameNatural

    ; Player's turn
    mov edx, OFFSET msgPlayerTurn
    call WriteString
    call Crlf

playerTurnLoop:
    ; Get player choice
    call GetPlayerChoice

    cmp al, 'S'
    je playerStands

    ; Player hits
    call DrawCard

    ; Add card to player hand
    mov ecx, playerHandSize
    mov esi, OFFSET playerHand
    shl ecx, 2            ; convert to byte offset
    add esi, ecx
    mov [esi], eax        ; store new card

    ; Increment hand size
    inc playerHandSize

    ; Display new card
    mov edx, OFFSET msgNewCard
    call WriteString
    call GetCardName
    call WriteString
    call Crlf

    ; Display updated hand
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    call DisplayHand
    call Crlf

    ; Check if player busted
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    call CalculateHandValue
    cmp eax, 21
    ja playerBusted
    je playerStands       ; if exactly 21, automatically stand

    ; Continue player turn
    jmp playerTurnLoop

playerStands:
    call Crlf
    ; Dealer's turn
    mov edx, OFFSET msgDealerTurn
    call WriteString
    call Crlf
    call DealerPlay
    jmp endGame

playerBusted:
    ; Player busted, dealer wins automatically
    call Crlf

endGameNatural:
endGame:
    ; Determine and display winner
    call Crlf
    mov edx, OFFSET msgGameOver
    call WriteString
    call Crlf
    call DetermineWinner
    call Crlf

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
PlayBlackjack ENDP

;------------------------------------------
; GetPlayerChoice PROC
; Description: Prompts the user for Hit or Stand and validates input
; Input: None
; Output: AL = 'H' for Hit, 'S' for Stand (uppercase)
; Modifies: AL, EDX
;------------------------------------------
GetPlayerChoice PROC
    push edx

promptLoop:
    ; Display prompt
    mov edx, OFFSET msgPrompt
    call WriteString

    ; Read single character
    call ReadChar
    call WriteChar        ; Echo the character
    call Crlf

    ; Convert to uppercase for comparison
    cmp al, 'a'
    jb checkValid         ; if < 'a', already uppercase or invalid
    cmp al, 'z'
    ja checkValid         ; if > 'z', invalid
    sub al, 32            ; convert lowercase to uppercase

checkValid:
    ; Check if H or S
    cmp al, 'H'
    je validChoice
    cmp al, 'S'
    je validChoice

    ; Invalid input - show error and retry
    mov edx, OFFSET msgInvalidInput
    call WriteString
    call Crlf
    jmp promptLoop

validChoice:
    mov playerChoice, al
    pop edx
    ret
GetPlayerChoice ENDP

;------------------------------------------
; DisplayHand PROC
; Description: Helper to display a hand and its total
; Input: ESI = pointer to hand array
;        ECX = hand size
;------------------------------------------
DisplayHand PROC
    push ecx
    push esi
    push eax
    push edx
    push ebx
    push edi

    mov ebx, ecx          ; save hand size
    mov edi, 0            ; counter for commas

    ; Display "Hand: "
    mov edx, OFFSET msgHand
    call WriteString

    ; Display each card
    mov ecx, ebx
displayLoop:
    ; Add comma separator (except before first card)
    cmp edi, 0
    je skipComma
    push eax
    mov edx, OFFSET msgComma
    call WriteString
    pop eax

skipComma:
    ; Get card rank and display its name
    mov eax, [esi]
    call GetCardName      ; EDX = pointer to card name
    call WriteString

    inc edi               ; increment card counter
    add esi, 4
    loop displayLoop

    ; Calculate and display total
    ; Reset ESI to start of hand (subtract hand_size * 4 bytes)
    mov edx, ebx
    shl edx, 2            ; edx = hand_size * 4
    sub esi, edx          ; ESI back to start of hand
    mov ecx, ebx          ; ECX = hand size for CalculateHandValue
    call CalculateHandValue

    mov edx, OFFSET msgTotal
    call WriteString
    call WriteDec
    call Crlf

    pop edi
    pop ebx
    pop edx
    pop eax
    pop esi
    pop ecx
    ret
DisplayHand ENDP

;------------------------------------------
; DisplayGameState PROC
; Description: Displays player's full hand and dealer's visible card
; Input: None (uses playerHand, playerHandSize, dealerHand arrays)
; Output: None
; Modifies: EAX, ECX, EDX, ESI
;------------------------------------------
DisplayGameState PROC
    push eax
    push ecx
    push edx
    push esi

    call Crlf

    ; Display dealer's hand (only first card visible)
    mov edx, OFFSET msgDealerHidden
    call WriteString

    ; Show first dealer card
    mov eax, dealerHand[0]
    call GetCardName
    call WriteString
    call Crlf

    ; Display player's full hand
    mov edx, OFFSET msgPlayerHand
    call WriteString

    ; Display all player cards with commas
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    mov edi, 0            ; comma counter

displayPlayerLoop:
    cmp ecx, 0
    je doneDisplaying

    ; Add comma separator (except before first card)
    cmp edi, 0
    je skipPlayerComma
    push eax
    mov edx, OFFSET msgComma
    call WriteString
    pop eax

skipPlayerComma:
    ; Display card name
    mov eax, [esi]
    call GetCardName
    call WriteString

    inc edi
    add esi, 4
    dec ecx
    jmp displayPlayerLoop

doneDisplaying:
    ; Calculate and display player total
    mov esi, OFFSET playerHand
    mov ecx, playerHandSize
    call CalculateHandValue

    mov edx, OFFSET msgTotal
    call WriteString
    call WriteDec
    call Crlf
    call Crlf

    pop esi
    pop edx
    pop ecx
    pop eax
    ret
DisplayGameState ENDP

;------------------------------------------
; main PROC
; Description: Entry point - starts the blackjack game
;------------------------------------------
main PROC
    call Randomize        ; Seed random number generator

    ; Play blackjack game
    call PlayBlackjack

    invoke ExitProcess, 0
main ENDP
END main

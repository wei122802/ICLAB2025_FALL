import random
from itertools import combinations

def generate_poker_input(num_patterns=100, num_players=9, output_file='input.txt'):
    """
    Generate Texas Hold'em poker input file
    
    Parameters:
    - num_patterns: number of test patterns
    - num_players: number of players (default 9)
    - output_file: output filename
    
    Card numbers: 2-14 (A=14, K=13, Q=12, J=11)
    Card suits: 0=Clubs, 1=Diamonds, 2=Hearts, 3=Spades
    """
    
    with open(output_file, 'w') as f:
        # Write number of patterns
        f.write(f"{num_patterns}\n")
        
        for pattern in range(num_patterns):
            # Create deck of 52 cards
            deck = []
            for num in range(2, 15):  # 2 to 14 (Ace)
                for suit in range(4):  # 0 to 3
                    deck.append((num, suit))
            
            # Shuffle deck
            random.shuffle(deck)
            
            # Deal cards
            card_idx = 0
            
            # Deal hole cards to each player (2 cards per player)
            player_holes = []
            for player in range(num_players):
                hole1 = deck[card_idx]
                card_idx += 1
                hole2 = deck[card_idx]
                card_idx += 1
                player_holes.append((hole1, hole2))
                # Write hole cards: num1 suit1 num2 suit2
                f.write(f"{hole1[0]} {hole1[1]} {hole2[0]} {hole2[1]}\n")
            
            # Deal 3 community cards (flop)
            flop = []
            for i in range(3):
                flop.append(deck[card_idx])
                card_idx += 1
            
            # Write flop: num1 suit1 num2 suit2 num3 suit3
            f.write(f"{flop[0][0]} {flop[0][1]} {flop[1][0]} {flop[1][1]} {flop[2][0]} {flop[2][1]}\n")
            
            # Calculate win rates for each player
            win_rates = calculate_win_rates(player_holes, flop, deck[card_idx:])
            
            # Write win rates (player 8 to player 0)
            win_rate_str = ' '.join(str(wr) for wr in reversed(win_rates))
            f.write(f"{win_rate_str}\n")
    
    print(f"Generated {num_patterns} patterns in {output_file}")


def calculate_win_rates(player_holes, flop, remaining_deck):
    """
    Calculate win rate for each player by simulating all possible turn and river
    
    Parameters:
    - player_holes: list of (hole1, hole2) for each player
    - flop: list of 3 community cards
    - remaining_deck: remaining cards in deck (31 cards: 52 - 18 hole cards - 3 flop = 31)
    
    Returns:
    - list of win rates (percentages) for each player
    """
    num_players = len(player_holes)
    wins = [0] * num_players
    total_simulations = 0
    
    # Try all possible combinations of turn and river (C(31,2) = 465 combinations)
    for turn_river in combinations(remaining_deck, 2):
        community_cards = flop + list(turn_river)
        
        # Evaluate hand for each player
        player_ranks = []
        for player_idx in range(num_players):
            hole1, hole2 = player_holes[player_idx]
            all_cards = [hole1, hole2] + community_cards
            rank, value = evaluate_best_hand(all_cards)
            player_ranks.append((rank, value, player_idx))
        
        # Find winner(s)
        player_ranks.sort(key=lambda x: (x[0], x[1]), reverse=True)
        best_rank = player_ranks[0][0]
        best_value = player_ranks[0][1]
        
        # Count winners (handle ties)
        winners = []
        for rank, value, player_idx in player_ranks:
            if rank == best_rank and value == best_value:
                winners.append(player_idx)
        
        # Award wins (split if tie)
        for winner_idx in winners:
            wins[winner_idx] += 1.0 / len(winners)
        
        total_simulations += 1
    
    # Calculate win rates as percentages (truncate only at the end)
    # Convert to percentage first, then truncate
    win_rates = [int((w / total_simulations) * 100) for w in wins]
    
    # NOTE: Sum may not be 100 due to truncation
    # This is expected behavior as per requirement
    
    return win_rates


def evaluate_best_hand(cards):
    """
    Evaluate the best 5-card poker hand from 7 cards
    
    Parameters:
    - cards: list of (num, suit) tuples (7 cards)
    
    Returns:
    - (rank, value): rank is hand type (1-10), value is tiebreaker
    """
    best_rank = 0
    best_value = 0
    
    # Try all combinations of 5 cards from 7
    for five_cards in combinations(cards, 5):
        rank, value = evaluate_five_cards(list(five_cards))
        if rank > best_rank or (rank == best_rank and value > best_value):
            best_rank = rank
            best_value = value
    
    return best_rank, best_value


def evaluate_five_cards(cards):
    """
    Evaluate a 5-card poker hand
    
    Returns:
    - (rank, value): rank 1-10, value for tiebreaking
    """
    # Sort cards by number (descending)
    cards = sorted(cards, key=lambda x: x[0], reverse=True)
    nums = [c[0] for c in cards]
    suits = [c[1] for c in cards]
    
    # Check flush
    is_flush = len(set(suits)) == 1
    
    # Check straight
    is_straight = False
    straight_high = 0
    if nums[0] - nums[4] == 4 and len(set(nums)) == 5:
        is_straight = True
        straight_high = nums[0]
    # Check A-2-3-4-5 (wheel)
    if nums[0] == 14 and nums[1] == 5 and nums[2] == 4 and nums[3] == 3 and nums[4] == 2:
        is_straight = True
        straight_high = 5
    
    # Count occurrences
    num_counts = {}
    for n in nums:
        num_counts[n] = num_counts.get(n, 0) + 1
    
    counts = sorted(num_counts.items(), key=lambda x: (x[1], x[0]), reverse=True)
    
    # Determine hand rank
    count_pattern = [c[1] for c in counts]
    
    # Royal Flush
    if is_straight and is_flush and nums[0] == 14 and straight_high == 14:
        return 10, nums[0] * 10000 + nums[1] * 1000 + nums[2] * 100 + nums[3] * 10 + nums[4]
    
    # Straight Flush
    if is_straight and is_flush:
        if straight_high == 5:
            return 9, 5 * 10000 + 4 * 1000 + 3 * 100 + 2 * 10 + 1
        return 9, straight_high * 10000 + (straight_high-1) * 1000 + (straight_high-2) * 100 + (straight_high-3) * 10 + (straight_high-4)
    
    # Four of a Kind
    if count_pattern == [4, 1]:
        quads = counts[0][0]
        kicker = counts[1][0]
        return 8, quads * 10000 + kicker * 1000
    
    # Full House
    if count_pattern == [3, 2]:
        trips = counts[0][0]
        pair = counts[1][0]
        return 7, trips * 10000 + pair * 1000
    
    # Flush
    if is_flush:
        return 6, nums[0] * 10000 + nums[1] * 1000 + nums[2] * 100 + nums[3] * 10 + nums[4]
    
    # Straight
    if is_straight:
        if straight_high == 5:
            return 5, 5 * 10000 + 4 * 1000 + 3 * 100 + 2 * 10 + 1
        return 5, straight_high * 10000 + (straight_high-1) * 1000 + (straight_high-2) * 100 + (straight_high-3) * 10 + (straight_high-4)
    
    # Three of a Kind
    if count_pattern == [3, 1, 1]:
        trips = counts[0][0]
        kickers_sorted = sorted([counts[1][0], counts[2][0]], reverse=True)
        return 4, trips * 10000 + kickers_sorted[0] * 1000 + kickers_sorted[1] * 100
    
    # Two Pair
    if count_pattern == [2, 2, 1]:
        pairs_sorted = sorted([counts[0][0], counts[1][0]], reverse=True)
        kicker = counts[2][0]
        return 3, pairs_sorted[0] * 10000 + pairs_sorted[1] * 1000 + kicker * 100
    
    # One Pair
    if count_pattern == [2, 1, 1, 1]:
        pair = counts[0][0]
        kickers_sorted = sorted([counts[1][0], counts[2][0], counts[3][0]], reverse=True)
        return 2, pair * 10000 + kickers_sorted[0] * 1000 + kickers_sorted[1] * 100 + kickers_sorted[2] * 10
    
    # High Card
    return 1, nums[0] * 10000 + nums[1] * 1000 + nums[2] * 100 + nums[3] * 10 + nums[4]


if __name__ == "__main__":
    # Generate input file with 100 patterns
    generate_poker_input(num_patterns=100, num_players=9, output_file='input.txt')
    print("Done! Check input.txt")
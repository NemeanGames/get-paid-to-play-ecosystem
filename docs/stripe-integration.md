# Stripe Integration Guide - Get Paid to Play Ecosystem

## 🎯 Overview

This guide covers the complete integration of Stripe payment processing into the Get Paid to Play (GPTP) ecosystem. Stripe handles both incoming payments from players and outgoing payouts to winners.

## 📋 Table of Contents

1. [Account Setup](#account-setup)
2. [API Configuration](#api-configuration)
3. [Frontend Integration](#frontend-integration)
4. [Backend Integration](#backend-integration)
5. [Payment Products](#payment-products)
6. [Connect for Payouts](#connect-for-payouts)
7. [Webhooks](#webhooks)
8. [Testing](#testing)
9. [Going Live](#going-live)
10. [Troubleshooting](#troubleshooting)

---

## 🔧 Account Setup

### Current Setup Status
- **Account**: Nemean Games sandbox
- **Mode**: Test/Development (ready for live activation)
- **Payment Method**: Embedded Components (Stripe Elements)
- **Integration Type**: Custom integration with React/Flask

### API Keys (Test Mode)
```bash
# Add to your .env file
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
```

⚠️ **Important**: These are test keys. Replace with live keys when going to production.

---

## ⚙️ API Configuration

### Environment Variables

Create or update your `.env` files:

#### Backend (.env)
```bash
# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
STRIPE_CONNECT_CLIENT_ID=ca_your_connect_client_id_here

# Payment Configuration
DEFAULT_CURRENCY=usd
PLATFORM_FEE_PERCENTAGE=10  # Platform takes 10% of entry fees
MINIMUM_PAYOUT_AMOUNT=5.00  # Minimum $5 for payouts
```

#### Frontend (.env)
```bash
# Stripe Configuration
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
REACT_APP_API_BASE_URL=http://localhost:5000/api
```

---

## 🎨 Frontend Integration

### 1. Install Stripe Dependencies

```bash
cd frontend
npm install @stripe/stripe-js @stripe/react-stripe-js
```

### 2. Stripe Provider Setup

Create `src/components/StripeProvider.js`:

```javascript
import React from 'react';
import { loadStripe } from '@stripe/stripe-js';
import { Elements } from '@stripe/react-stripe-js';

const stripePromise = loadStripe(process.env.REACT_APP_STRIPE_PUBLISHABLE_KEY);

const StripeProvider = ({ children }) => {
  return (
    <Elements stripe={stripePromise}>
      {children}
    </Elements>
  );
};

export default StripeProvider;
```

### 3. Payment Component

Create `src/components/GameEntryPayment.js`:

```javascript
import React, { useState, useEffect } from 'react';
import {
  useStripe,
  useElements,
  CardElement,
  PaymentElement
} from '@stripe/react-stripe-js';
import axios from 'axios';

const GameEntryPayment = ({ gameId, entryFee, onSuccess, onError }) => {
  const stripe = useStripe();
  const elements = useElements();
  const [clientSecret, setClientSecret] = useState('');
  const [processing, setProcessing] = useState(false);

  useEffect(() => {
    // Create payment intent when component mounts
    createPaymentIntent();
  }, [gameId, entryFee]);

  const createPaymentIntent = async () => {
    try {
      const response = await axios.post('/api/payments/create-intent', {
        game_id: gameId,
        amount: entryFee * 100, // Convert to cents
        currency: 'usd'
      }, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      
      setClientSecret(response.data.client_secret);
    } catch (error) {
      console.error('Error creating payment intent:', error);
      onError('Failed to initialize payment');
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    
    if (!stripe || !elements) {
      return;
    }

    setProcessing(true);

    const result = await stripe.confirmPayment({
      elements,
      confirmParams: {
        return_url: `${window.location.origin}/game/${gameId}/success`,
      },
      redirect: 'if_required'
    });

    if (result.error) {
      console.error('Payment failed:', result.error);
      onError(result.error.message);
    } else {
      console.log('Payment succeeded:', result.paymentIntent);
      onSuccess(result.paymentIntent);
    }

    setProcessing(false);
  };

  if (!clientSecret) {
    return <div>Loading payment form...</div>;
  }

  return (
    <form onSubmit={handleSubmit} className="payment-form">
      <div className="payment-element">
        <PaymentElement />
      </div>
      
      <button 
        type="submit" 
        disabled={!stripe || processing}
        className="pay-button"
      >
        {processing ? 'Processing...' : `Pay $${entryFee} to Join Game`}
      </button>
    </form>
  );
};

export default GameEntryPayment;
```

### 4. App Integration

Update `src/App.js`:

```javascript
import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import StripeProvider from './components/StripeProvider';
import GameLobby from './components/GameLobby';
import GamePlay from './components/GamePlay';
import Dashboard from './components/Dashboard';

function App() {
  return (
    <StripeProvider>
      <Router>
        <div className="App">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/games" element={<GameLobby />} />
            <Route path="/game/:id" element={<GamePlay />} />
          </Routes>
        </div>
      </Router>
    </StripeProvider>
  );
}

export default App;
```

---

## 🔧 Backend Integration

### 1. Install Stripe Dependencies

```bash
cd backend
pip install stripe python-dotenv
```

### 2. Stripe Configuration

Create `backend/config/stripe_config.py`:

```python
import stripe
import os
from dotenv import load_dotenv

load_dotenv()

# Configure Stripe
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')

class StripeConfig:
    SECRET_KEY = os.getenv('STRIPE_SECRET_KEY')
    WEBHOOK_SECRET = os.getenv('STRIPE_WEBHOOK_SECRET')
    CONNECT_CLIENT_ID = os.getenv('STRIPE_CONNECT_CLIENT_ID')
    DEFAULT_CURRENCY = os.getenv('DEFAULT_CURRENCY', 'usd')
    PLATFORM_FEE_PERCENTAGE = float(os.getenv('PLATFORM_FEE_PERCENTAGE', 10))
    MINIMUM_PAYOUT_AMOUNT = float(os.getenv('MINIMUM_PAYOUT_AMOUNT', 5.00))
```

### 3. Payment Service

Create `backend/services/payment_service.py`:

```python
import stripe
from flask import current_app
from backend.models import User, Game, GameSession, Payment
from backend.config.stripe_config import StripeConfig

class PaymentService:
    
    @staticmethod
    def create_payment_intent(user_id, game_id, amount, currency='usd'):
        """Create a payment intent for game entry."""
        try:
            # Calculate platform fee
            platform_fee = int(amount * StripeConfig.PLATFORM_FEE_PERCENTAGE / 100)
            
            intent = stripe.PaymentIntent.create(
                amount=amount,  # Amount in cents
                currency=currency,
                application_fee_amount=platform_fee,
                metadata={
                    'user_id': user_id,
                    'game_id': game_id,
                    'type': 'game_entry'
                }
            )
            
            # Store payment record
            payment = Payment(
                user_id=user_id,
                game_id=game_id,
                stripe_payment_intent_id=intent.id,
                amount=amount / 100,  # Store in dollars
                currency=currency,
                status='pending'
            )
            payment.save()
            
            return intent
            
        except stripe.error.StripeError as e:
            current_app.logger.error(f"Stripe error: {e}")
            raise Exception(f"Payment processing error: {e}")
    
    @staticmethod
    def confirm_payment(payment_intent_id):
        """Confirm payment and update records."""
        try:
            intent = stripe.PaymentIntent.retrieve(payment_intent_id)
            
            if intent.status == 'succeeded':
                # Update payment record
                payment = Payment.query.filter_by(
                    stripe_payment_intent_id=payment_intent_id
                ).first()
                
                if payment:
                    payment.status = 'completed'
                    payment.save()
                    
                    # Create game session for user
                    game_session = GameSession(
                        user_id=payment.user_id,
                        game_id=payment.game_id,
                        payment_id=payment.id,
                        status='active'
                    )
                    game_session.save()
                    
                    return True
            
            return False
            
        except stripe.error.StripeError as e:
            current_app.logger.error(f"Stripe error: {e}")
            return False
    
    @staticmethod
    def create_payout(user_id, amount, description="Game winnings"):
        """Create payout to user (requires Stripe Connect)."""
        try:
            user = User.query.get(user_id)
            if not user or not user.stripe_account_id:
                raise Exception("User not connected to Stripe")
            
            if amount < StripeConfig.MINIMUM_PAYOUT_AMOUNT:
                raise Exception(f"Minimum payout amount is ${StripeConfig.MINIMUM_PAYOUT_AMOUNT}")
            
            transfer = stripe.Transfer.create(
                amount=int(amount * 100),  # Convert to cents
                currency=StripeConfig.DEFAULT_CURRENCY,
                destination=user.stripe_account_id,
                description=description,
                metadata={
                    'user_id': user_id,
                    'type': 'game_winnings'
                }
            )
            
            return transfer
            
        except stripe.error.StripeError as e:
            current_app.logger.error(f"Stripe payout error: {e}")
            raise Exception(f"Payout processing error: {e}")
```

### 4. Payment Routes

Create `backend/routes/payment_routes.py`:

```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend.services.payment_service import PaymentService
from backend.models import Game

payment_bp = Blueprint('payments', __name__)

@payment_bp.route('/create-intent', methods=['POST'])
@jwt_required()
def create_payment_intent():
    """Create payment intent for game entry."""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        game_id = data.get('game_id')
        amount = data.get('amount')  # Amount in cents
        currency = data.get('currency', 'usd')
        
        # Validate game exists
        game = Game.query.get(game_id)
        if not game:
            return jsonify({'error': 'Game not found'}), 404
        
        # Create payment intent
        intent = PaymentService.create_payment_intent(
            user_id=user_id,
            game_id=game_id,
            amount=amount,
            currency=currency
        )
        
        return jsonify({
            'client_secret': intent.client_secret,
            'payment_intent_id': intent.id
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payment_bp.route('/confirm', methods=['POST'])
@jwt_required()
def confirm_payment():
    """Confirm payment completion."""
    try:
        data = request.get_json()
        payment_intent_id = data.get('payment_intent_id')
        
        success = PaymentService.confirm_payment(payment_intent_id)
        
        if success:
            return jsonify({'status': 'success'})
        else:
            return jsonify({'error': 'Payment confirmation failed'}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@payment_bp.route('/payout', methods=['POST'])
@jwt_required()
def create_payout():
    """Create payout to user."""
    try:
        user_id = get_jwt_identity()
        data = request.get_json()
        
        amount = data.get('amount')
        description = data.get('description', 'Game winnings')
        
        transfer = PaymentService.create_payout(
            user_id=user_id,
            amount=amount,
            description=description
        )
        
        return jsonify({
            'transfer_id': transfer.id,
            'status': 'success'
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400
```

---

## 🎮 Payment Products

### Current Products

#### 1. Game Entry Fee
- **Name**: Game Entry Fee
- **Price**: $5.00 USD
- **Type**: One-time payment
- **Description**: Entry fee for competitive games
- **Use Case**: Players pay to join games and compete for rewards

### Creating Additional Products

You can create more products in the Stripe Dashboard or via API:

```python
# Example: Create Premium Membership product
stripe.Product.create(
    name='Premium Membership',
    description='Monthly premium membership with exclusive features',
    type='service'
)

stripe.Price.create(
    product='prod_premium_membership_id',
    unit_amount=999,  # $9.99
    currency='usd',
    recurring={'interval': 'month'}
)
```

### Recommended Products for GPTP

1. **Tournament Entry** - $10-50 depending on prize pool
2. **Premium Membership** - $9.99/month for exclusive features
3. **Power-ups/Boosts** - $0.99-2.99 for in-game advantages
4. **Custom Avatar** - $4.99 for personalization
5. **VIP Status** - $19.99/month for premium benefits

---

## 💸 Connect for Payouts

Stripe Connect allows you to pay out winnings to players. This requires additional setup:

### 1. Enable Connect

1. Go to Stripe Dashboard → Connect
2. Enable Connect for your account
3. Set up your platform profile
4. Configure onboarding flow

### 2. Connect Integration

```python
# Create Connect account for user
def create_connect_account(user):
    account = stripe.Account.create(
        type='express',
        country='US',
        email=user.email,
        capabilities={
            'card_payments': {'requested': True},
            'transfers': {'requested': True},
        },
    )
    
    user.stripe_account_id = account.id
    user.save()
    
    return account

# Create onboarding link
def create_onboarding_link(account_id):
    account_link = stripe.AccountLink.create(
        account=account_id,
        refresh_url='https://yoursite.com/connect/refresh',
        return_url='https://yoursite.com/connect/success',
        type='account_onboarding',
    )
    
    return account_link.url
```

### 3. Payout Flow

```python
# Automatic payout after game completion
def process_game_payouts(game_session_id):
    session = GameSession.query.get(game_session_id)
    
    if session.status == 'completed':
        # Calculate winnings based on performance
        winnings = calculate_winnings(session)
        
        if winnings > 0:
            PaymentService.create_payout(
                user_id=session.user_id,
                amount=winnings,
                description=f"Winnings from game {session.game.name}"
            )
```

---

## 🔔 Webhooks

Webhooks ensure your system stays synchronized with Stripe events.

### 1. Webhook Endpoint

Create `backend/routes/webhook_routes.py`:

```python
import stripe
from flask import Blueprint, request, jsonify
from backend.config.stripe_config import StripeConfig
from backend.services.payment_service import PaymentService

webhook_bp = Blueprint('webhooks', __name__)

@webhook_bp.route('/stripe', methods=['POST'])
def stripe_webhook():
    payload = request.get_data(as_text=True)
    sig_header = request.headers.get('Stripe-Signature')
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, StripeConfig.WEBHOOK_SECRET
        )
    except ValueError:
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError:
        return jsonify({'error': 'Invalid signature'}), 400
    
    # Handle the event
    if event['type'] == 'payment_intent.succeeded':
        payment_intent = event['data']['object']
        PaymentService.confirm_payment(payment_intent['id'])
        
    elif event['type'] == 'payment_intent.payment_failed':
        payment_intent = event['data']['object']
        # Handle failed payment
        handle_payment_failure(payment_intent)
        
    elif event['type'] == 'transfer.created':
        transfer = event['data']['object']
        # Handle successful payout
        handle_payout_success(transfer)
    
    return jsonify({'status': 'success'})

def handle_payment_failure(payment_intent):
    # Update payment record and notify user
    pass

def handle_payout_success(transfer):
    # Update user balance and send notification
    pass
```

### 2. Webhook Configuration

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add endpoint: `https://yourdomain.com/api/webhooks/stripe`
3. Select events:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `transfer.created`
   - `account.updated`

---

## 🧪 Testing

### Test Cards

Use these test card numbers in development:

```
# Successful payments
4242424242424242 - Visa
4000056655665556 - Visa (debit)
5555555555554444 - Mastercard

# Failed payments
4000000000000002 - Card declined
4000000000009995 - Insufficient funds
4000000000009987 - Lost card
```

### Test Scenarios

1. **Successful Game Entry**
   - Use test card 4242424242424242
   - Verify payment intent creation
   - Confirm game session is created
   - Check webhook events

2. **Failed Payment**
   - Use test card 4000000000000002
   - Verify error handling
   - Check user is not added to game

3. **Payout Testing**
   - Create test Connect account
   - Process test payout
   - Verify transfer completion

### Testing Checklist

- [ ] Payment intent creation
- [ ] Successful payment flow
- [ ] Failed payment handling
- [ ] Webhook event processing
- [ ] Connect account creation
- [ ] Payout processing
- [ ] Error handling and logging
- [ ] UI/UX payment flow

---

## 🚀 Going Live

### Pre-Launch Checklist

1. **Account Verification**
   - [ ] Complete business verification in Stripe Dashboard
   - [ ] Activate live mode
   - [ ] Update API keys to live keys

2. **Security Review**
   - [ ] Implement proper error handling
   - [ ] Secure API endpoints
   - [ ] Validate webhook signatures
   - [ ] Implement rate limiting

3. **Testing**
   - [ ] Complete end-to-end testing
   - [ ] Test all payment scenarios
   - [ ] Verify webhook handling
   - [ ] Load testing for high volume

4. **Compliance**
   - [ ] PCI compliance review
   - [ ] Privacy policy updates
   - [ ] Terms of service updates
   - [ ] GDPR compliance (if applicable)

### Live Configuration

Update environment variables:

```bash
# Production API Keys
STRIPE_SECRET_KEY=sk_live_your_live_secret_key
STRIPE_PUBLISHABLE_KEY=pk_live_your_live_publishable_key
STRIPE_WEBHOOK_SECRET=whsec_your_live_webhook_secret
```

---

## 🔍 Troubleshooting

### Common Issues

#### 1. Payment Intent Creation Fails
```
Error: "This payment intent cannot be confirmed because it's missing a payment method"
```
**Solution**: Ensure PaymentElement is properly configured and user has entered payment details.

#### 2. Webhook Signature Verification Fails
```
Error: "Invalid signature"
```
**Solution**: Check webhook secret matches the one in Stripe Dashboard.

#### 3. Connect Account Issues
```
Error: "No such destination: 'acct_xxx'"
```
**Solution**: Ensure user has completed Connect onboarding and account is active.

#### 4. Insufficient Permissions
```
Error: "You do not have permission to access this resource"
```
**Solution**: Check API key permissions and account capabilities.

### Debug Mode

Enable debug logging:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
stripe.log = 'debug'
```

### Support Resources

- [Stripe Documentation](https://stripe.com/docs)
- [Stripe Support](https://support.stripe.com/)
- [Community Forum](https://stackoverflow.com/questions/tagged/stripe-payments)
- [Status Page](https://status.stripe.com/)

---

## 📊 Monitoring and Analytics

### Key Metrics to Track

1. **Payment Success Rate**
   - Target: >95% success rate
   - Monitor failed payment reasons

2. **Average Transaction Value**
   - Track game entry fees
   - Monitor premium purchases

3. **Payout Processing Time**
   - Target: <24 hours for payouts
   - Monitor transfer failures

4. **Revenue Metrics**
   - Platform fees collected
   - Total volume processed
   - Monthly recurring revenue (subscriptions)

### Stripe Dashboard

Use Stripe Dashboard to monitor:
- Real-time transaction data
- Revenue analytics
- Customer insights
- Dispute management
- Payout tracking

---

This guide provides everything needed to integrate Stripe into your Get Paid to Play ecosystem. For additional support or custom requirements, refer to the Stripe documentation or contact their support team.


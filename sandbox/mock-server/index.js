const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

app.use(bodyParser.json());

// Fixture loader middleware
const loadFixtures = (req, res, next) => {
    // Load fixtures from a predefined source
    req.fixtures = {}; // Sample fixture
    next();
};

app.use(loadFixtures);

// OAuth2 endpoint
app.post('/oauth2/token', (req, res) => {
    // Handle OAuth2 token requests
    res.json({ accessToken: 'sampleAccessToken' });
});

// Accounts endpoint
app.get('/accounts', (req, res) => {
    // List accounts
    res.json(req.fixtures.accounts || []);
});

// Payments endpoint
app.post('/payments', (req, res) => {
    // Process a payment
    res.json({ status: 'Payment processed' });
});

// Merchant endpoint
app.get('/merchants', (req, res) => {
    // List merchants
    res.json(req.fixtures.merchants || []);
});

// KYC endpoint
app.post('/kyc', (req, res) => {
    // Submit KYC information
    res.json({ status: 'KYC submitted' });
});

// Lending endpoint
app.get('/lending', (req, res) => {
    // Get lending options
    res.json(req.fixtures.lending || []);
});

// Idempotency support
const idempotencyMiddleware = (req, res, next) => {
    const idempotencyKey = req.headers['idempotency-key'];
    if (idempotencyKey) {
        // Check if a response is already recorded for this key
        // If recorded, return the response; otherwise, proceed
        next();
    } else {
        next();
    }
};

app.use(idempotencyMiddleware);

app.listen(port, () => {
    console.log(`Mock server running at http://localhost:${port}`);
});

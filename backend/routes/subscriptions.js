const express = require('express');
const router = express.Router();
const { Subscription, SubscriptionPlan, SubscriptionDelivery } = require('../models/Subscription');
const { protect } = require('../middleware/auth');
const { verifyFirebaseToken } = require('../middleware/firebaseAuth');

// SUBSCRIPTION PLANS MANAGEMENT ENDPOINTS (must be before /:id routes)
// ============================================================================

// Get all subscription plans
router.get('/plans', async (req, res) => {
    try {
        const filter = {};
        
        // Filter by active status if specified
        if (req.query.active !== undefined) {
            filter.isActive = req.query.active === 'true';
        }
        
        // Filter by frequency if specified
        if (req.query.frequency) {
            filter.frequency = req.query.frequency;
        }
        
        const plans = await SubscriptionPlan.find(filter)
            .sort({ sortOrder: 1, createdAt: -1 })
            .lean();
        
        res.json({
            success: true,
            data: {
                plans,
                total: plans.length
            }
        });
    } catch (error) {
        console.error('Error fetching subscription plans:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscription plans',
            error: error.message
        });
    }
});

// Get single subscription plan by ID
router.get('/plans/:id', async (req, res) => {
    try {
        const plan = await SubscriptionPlan.findById(req.params.id).lean();
        
        if (!plan) {
            return res.status(404).json({
                success: false,
                message: 'Subscription plan not found'
            });
        }
        
        res.json({
            success: true,
            data: plan
        });
    } catch (error) {
        console.error('Error fetching subscription plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscription plan',
            error: error.message
        });
    }
});

// Create new subscription plan
router.post('/plans', async (req, res) => {
    try {
        const {
            planId,
            name,
            description,
            frequency,
            discountPercentage,
            minCommitmentMonths,
            benefits,
            isActive,
            sortOrder
        } = req.body;
        
        // Validate required fields
        if (!planId || !name || !description || !frequency || discountPercentage === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: planId, name, description, frequency, discountPercentage'
            });
        }

        const plan = new SubscriptionPlan({
            planId,
            name,
            description,
            frequency,
            discountPercentage,
            minCommitmentMonths: minCommitmentMonths || 1,
            benefits: benefits || [],
            isActive: isActive !== undefined ? isActive : true,
            sortOrder: sortOrder || 0
        });

        const savedPlan = await plan.save();
        
        res.status(201).json({
            success: true,
            message: 'Subscription plan created successfully',
            data: savedPlan
        });
    } catch (error) {
        console.error('Error creating subscription plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create subscription plan',
            error: error.message
        });
    }
});

// ============================================================================
// SUBSCRIPTION MANAGEMENT ENDPOINTS
// ============================================================================

// Get all subscriptions with filtering and pagination
router.get('/', verifyFirebaseToken, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;
        
        const filter = {};
        
        // Apply filters
        if (req.query.status) {
            filter.status = req.query.status;
        }
        
        if (req.query.userId) {
            filter.userId = req.query.userId;
        }
        
        if (req.query.frequency) {
            filter.frequency = req.query.frequency;
        }
        
        if (req.query.search) {
            const searchRegex = new RegExp(req.query.search, 'i');
            filter.$or = [
                { 'user.name': searchRegex },
                { 'user.email': searchRegex },
                { 'products.name': searchRegex }
            ];
        }

        const subscriptions = await Subscription.find(filter)
            .populate('userId', 'name email')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean();

        const total = await Subscription.countDocuments(filter);
        const totalPages = Math.ceil(total / limit);

        res.json({
            success: true,
            data: subscriptions,
            pagination: {
                current: page,
                pages: totalPages,
                total: total,
                hasNext: page < totalPages,
                hasPrev: page > 1
            }
        });
    } catch (error) {
        console.error('Error fetching subscriptions:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching subscriptions',
            error: error.message
        });
    }
});

// Get subscription by ID
router.get('/:id', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id)
            .populate('userId', 'name email phone')
            .lean();

        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        res.json({
            success: true,
            data: subscription
        });
    } catch (error) {
        console.error('Error fetching subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching subscription',
            error: error.message
        });
    }
});

// Create new subscription
router.post('/', verifyFirebaseToken, async (req, res) => {
    try {
        const subscriptionData = {
            userId: req.body.userId,
            user: req.body.user,
            products: req.body.products,
            frequency: req.body.frequency,
            deliveryAddress: req.body.deliveryAddress,
            deliveryInstructions: req.body.deliveryInstructions,
            nextDeliveryDate: req.body.nextDeliveryDate,
            totalAmount: req.body.totalAmount,
            paymentMethod: req.body.paymentMethod,
            status: req.body.status || 'active'
        };

        const subscription = new Subscription(subscriptionData);
        await subscription.save();

        res.status(201).json({
            success: true,
            message: 'Subscription created successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error creating subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error creating subscription',
            error: error.message
        });
    }
});

// Update subscription
router.put('/:id', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        // Update allowed fields
        const allowedUpdates = [
            'products', 'frequency', 'deliveryAddress', 'deliveryInstructions',
            'nextDeliveryDate', 'totalAmount', 'paymentMethod', 'status'
        ];

        allowedUpdates.forEach(field => {
            if (req.body[field] !== undefined) {
                subscription[field] = req.body[field];
            }
        });

        subscription.updatedAt = new Date();
        await subscription.save();

        res.json({
            success: true,
            message: 'Subscription updated successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error updating subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating subscription',
            error: error.message
        });
    }
});

// Pause subscription
router.post('/:id/pause', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        if (subscription.status !== 'active') {
            return res.status(400).json({
                success: false,
                message: 'Only active subscriptions can be paused'
            });
        }

        const pausedUntil = req.body.pausedUntil || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days default
        const reason = req.body.reason || 'User requested';

        subscription.status = 'paused';
        subscription.pausedUntil = pausedUntil;
        subscription.pauseReason = reason;
        subscription.updatedAt = new Date();

        await subscription.save();

        res.json({
            success: true,
            message: 'Subscription paused successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error pausing subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error pausing subscription',
            error: error.message
        });
    }
});

// Resume subscription
router.post('/:id/resume', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        if (subscription.status !== 'paused') {
            return res.status(400).json({
                success: false,
                message: 'Only paused subscriptions can be resumed'
            });
        }

        subscription.status = 'active';
        subscription.pausedUntil = null;
        subscription.pauseReason = null;
        
        // Calculate next delivery date
        const today = new Date();
        let nextDelivery = new Date(today);
        
        switch (subscription.frequency) {
            case 'daily':
                nextDelivery.setDate(today.getDate() + 1);
                break;
            case 'weekly':
                nextDelivery.setDate(today.getDate() + 7);
                break;
            case 'bi-weekly':
                nextDelivery.setDate(today.getDate() + 14);
                break;
            case 'monthly':
                nextDelivery.setMonth(today.getMonth() + 1);
                break;
            default:
                nextDelivery.setDate(today.getDate() + 7);
        }
        
        subscription.nextDeliveryDate = nextDelivery;
        subscription.updatedAt = new Date();

        await subscription.save();

        res.json({
            success: true,
            message: 'Subscription resumed successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error resuming subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error resuming subscription',
            error: error.message
        });
    }
});

// Cancel subscription
router.post('/:id/cancel', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        if (subscription.status === 'cancelled') {
            return res.status(400).json({
                success: false,
                message: 'Subscription is already cancelled'
            });
        }

        const reason = req.body.reason || 'User requested';
        const refund = req.body.refund === true;

        subscription.status = 'cancelled';
        subscription.cancelledAt = new Date();
        subscription.cancellationReason = reason;
        subscription.refundIssued = refund;
        subscription.updatedAt = new Date();

        await subscription.save();

        res.json({
            success: true,
            message: 'Subscription cancelled successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error cancelling subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error cancelling subscription',
            error: error.message
        });
    }
});

// Add delivery record
router.post('/:id/deliveries', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        const delivery = {
            date: req.body.date || new Date(),
            status: req.body.status || 'pending',
            trackingNumber: req.body.trackingNumber,
            deliveryAddress: req.body.deliveryAddress || subscription.deliveryAddress,
            notes: req.body.notes,
            deliveredAt: req.body.status === 'delivered' ? new Date() : null
        };

        subscription.deliveries.push(delivery);

        // Update next delivery date if this delivery is completed
        if (req.body.status === 'delivered') {
            const nextDate = new Date();
            switch (subscription.frequency) {
                case 'daily':
                    nextDate.setDate(nextDate.getDate() + 1);
                    break;
                case 'weekly':
                    nextDate.setDate(nextDate.getDate() + 7);
                    break;
                case 'bi-weekly':
                    nextDate.setDate(nextDate.getDate() + 14);
                    break;
                case 'monthly':
                    nextDate.setMonth(nextDate.getMonth() + 1);
                    break;
            }
            subscription.nextDeliveryDate = nextDate;
        }

        subscription.updatedAt = new Date();
        await subscription.save();

        res.json({
            success: true,
            message: 'Delivery record added successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error adding delivery:', error);
        res.status(500).json({
            success: false,
            message: 'Error adding delivery record',
            error: error.message
        });
    }
});

// Update delivery status
router.put('/:id/deliveries/:deliveryId', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        const delivery = subscription.deliveries.id(req.params.deliveryId);
        
        if (!delivery) {
            return res.status(404).json({
                success: false,
                message: 'Delivery record not found'
            });
        }

        // Update delivery fields
        if (req.body.status) delivery.status = req.body.status;
        if (req.body.trackingNumber) delivery.trackingNumber = req.body.trackingNumber;
        if (req.body.notes) delivery.notes = req.body.notes;
        
        if (req.body.status === 'delivered' && !delivery.deliveredAt) {
            delivery.deliveredAt = new Date();
        }

        subscription.updatedAt = new Date();
        await subscription.save();

        res.json({
            success: true,
            message: 'Delivery updated successfully',
            data: subscription
        });
    } catch (error) {
        console.error('Error updating delivery:', error);
        res.status(500).json({
            success: false,
            message: 'Error updating delivery',
            error: error.message
        });
    }
});

// Get subscription statistics
router.get('/admin/stats', protect, async (req, res) => {
    try {
        const stats = await Promise.all([
            // Total subscriptions
            Subscription.countDocuments(),
            
            // Active subscriptions
            Subscription.countDocuments({ status: 'active' }),
            
            // Paused subscriptions
            Subscription.countDocuments({ status: 'paused' }),
            
            // Cancelled subscriptions
            Subscription.countDocuments({ status: 'cancelled' }),
            
            // Monthly revenue (sum of all active subscriptions)
            Subscription.aggregate([
                { $match: { status: 'active' } },
                { $group: { _id: null, total: { $sum: '$totalAmount' } } }
            ]),
            
            // Subscription frequency distribution
            Subscription.aggregate([
                { $group: { _id: '$frequency', count: { $sum: 1 } } }
            ]),
            
            // Recent subscriptions (last 7 days)
            Subscription.countDocuments({
                createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
            })
        ]);

        const [
            totalSubscriptions,
            activeSubscriptions,
            pausedSubscriptions,
            cancelledSubscriptions,
            revenueResult,
            frequencyDistribution,
            recentSubscriptions
        ] = stats;

        const monthlyRevenue = revenueResult.length > 0 ? revenueResult[0].total : 0;

        res.json({
            success: true,
            data: {
                totalSubscriptions,
                activeSubscriptions,
                pausedSubscriptions,
                cancelledSubscriptions,
                monthlyRevenue,
                recentSubscriptions,
                frequencyDistribution: frequencyDistribution.reduce((acc, item) => {
                    acc[item._id] = item.count;
                    return acc;
                }, {}),
                retentionRate: totalSubscriptions > 0 ? 
                    ((activeSubscriptions / totalSubscriptions) * 100).toFixed(1) : 0
            }
        });
    } catch (error) {
        console.error('Error fetching subscription stats:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching subscription statistics',
            error: error.message
        });
    }
});

// Delete subscription (admin only)
router.delete('/:id', verifyFirebaseToken, async (req, res) => {
    try {
        const subscription = await Subscription.findById(req.params.id);
        
        if (!subscription) {
            return res.status(404).json({
                success: false,
                message: 'Subscription not found'
            });
        }

        await Subscription.findByIdAndDelete(req.params.id);

        res.json({
            success: true,
            message: 'Subscription deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting subscription:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting subscription',
            error: error.message
        });
    }
});

// Admin: Get subscription statistics
router.get('/admin/stats', protect, async (req, res) => {
    try {
        const totalSubscriptions = await Subscription.countDocuments();
        const activeSubscriptions = await Subscription.countDocuments({ status: 'active' });
        const pausedSubscriptions = await Subscription.countDocuments({ status: 'paused' });
        const cancelledSubscriptions = await Subscription.countDocuments({ status: 'cancelled' });
        
        // Calculate MRR (Monthly Recurring Revenue)
        const mrrResult = await Subscription.aggregate([
            { $match: { status: 'active' } },
            {
                $group: {
                    _id: null,
                    totalMRR: { $sum: '$subscriptionPrice' }
                }
            }
        ]);
        
        const mrr = mrrResult.length > 0 ? mrrResult[0].totalMRR : 0;
        const retentionRate = totalSubscriptions > 0 ? ((activeSubscriptions / totalSubscriptions) * 100) : 0;
        
        res.json({
            success: true,
            data: {
                activeSubscriptions,
                mrr: Math.round(mrr * 100) / 100,
                pausedSubscriptions,
                cancelledSubscriptions,
                retentionRate: Math.round(retentionRate * 10) / 10,
                totalSubscriptions
            }
        });

    } catch (error) {
        console.error('Error fetching subscription stats:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscription statistics',
            error: error.message
        });
    }
});

// Admin: Get all subscriptions with user data
router.get('/admin/list', protect, async (req, res) => {
    try {
        const User = require('../models/User');
        const { status, page = 1, limit = 50 } = req.query;
        
        // Build query
        const query = {};
        if (status) {
            query.status = status;
        }
        
        // Fetch subscriptions
        const subscriptions = await Subscription.find(query)
            .sort({ createdAt: -1 })
            .limit(limit * 1)
            .skip((page - 1) * limit)
            .lean();
        
        // Get unique user IDs
        const userIds = [...new Set(subscriptions.map(s => s.userId))];
        
        // Fetch all users in one query
        const users = await User.find({
            firebaseUid: { $in: userIds }
        }).lean();
        
        const usersMap = {};
        users.forEach(user => {
            usersMap[user.firebaseUid] = user;
        });
        
        // Enrich subscriptions with user data
        const enrichedSubscriptions = subscriptions.map(subscription => {
            const user = usersMap[subscription.userId];
            
            return {
                _id: subscription._id,
                userId: subscription.userId,
                userName: user?.name || subscription.userName || 'Unknown',
                userEmail: user?.email || subscription.userEmail || 'Unknown',
                productId: subscription.productId,
                productName: subscription.productName,
                productSize: subscription.productSize,
                frequency: subscription.frequency,
                frequencyDisplay: subscription.frequencyDisplay,
                quantity: subscription.quantity,
                subscriptionPrice: subscription.subscriptionPrice,
                status: subscription.status,
                nextDelivery: subscription.nextDelivery,
                startDate: subscription.startDate,
                totalDeliveries: subscription.totalDeliveries,
                totalAmount: subscription.totalAmount,
                pauseReason: subscription.pauseReason,
                pausedUntil: subscription.pausedUntil,
                cancellationReason: subscription.cancellationReason,
                cancelledAt: subscription.cancelledAt,
                createdAt: subscription.createdAt
            };
        });
        
        // Get total count
        const total = await Subscription.countDocuments(query);
        
        res.json({
            success: true,
            data: {
                subscriptions: enrichedSubscriptions,
                pagination: {
                    currentPage: parseInt(page),
                    totalPages: Math.ceil(total / limit),
                    total
                }
            }
        });

    } catch (error) {
        console.error('Error fetching subscriptions list:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscriptions list',
            error: error.message
        });
    }
});

// ============================================================================
// SUBSCRIPTION PLANS MANAGEMENT ENDPOINTS
// ============================================================================

// Get all subscription plans
router.get('/plans', async (req, res) => {
    try {
        const filter = {};
        
        // Filter by active status if specified
        if (req.query.active !== undefined) {
            filter.isActive = req.query.active === 'true';
        }
        
        // Filter by frequency if specified
        if (req.query.frequency) {
            filter.frequency = req.query.frequency;
        }
        
        const plans = await SubscriptionPlan.find(filter)
            .sort({ sortOrder: 1, createdAt: -1 })
            .lean();
        
        res.json({
            success: true,
            data: {
                plans,
                total: plans.length
            }
        });
    } catch (error) {
        console.error('Error fetching subscription plans:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscription plans',
            error: error.message
        });
    }
});

// Get single subscription plan by ID
router.get('/plans/:id', async (req, res) => {
    try {
        const plan = await SubscriptionPlan.findById(req.params.id).lean();
        
        if (!plan) {
            return res.status(404).json({
                success: false,
                message: 'Subscription plan not found'
            });
        }
        
        res.json({
            success: true,
            data: plan
        });
    } catch (error) {
        console.error('Error fetching subscription plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch subscription plan',
            error: error.message
        });
    }
});

// Create new subscription plan
router.post('/plans', async (req, res) => {
    try {
        const {
            planId,
            name,
            description,
            frequency,
            discountPercentage,
            minCommitmentMonths,
            benefits,
            isActive,
            sortOrder
        } = req.body;
        
        // Validate required fields
        if (!planId || !name || !description || !frequency || discountPercentage === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Missing required fields: planId, name, description, frequency, discountPercentage'
            });
        }
        
        // Check if planId already exists
        const existingPlan = await SubscriptionPlan.findOne({ planId });
        if (existingPlan) {
            return res.status(400).json({
                success: false,
                message: 'A plan with this Plan ID already exists'
            });
        }
        
        // Create new plan
        const plan = new SubscriptionPlan({
            planId,
            name,
            description,
            frequency,
            discountPercentage,
            minCommitmentMonths: minCommitmentMonths || 1,
            benefits: benefits || [],
            isActive: isActive !== undefined ? isActive : true,
            sortOrder: sortOrder || 0
        });
        
        await plan.save();
        
        res.status(201).json({
            success: true,
            message: 'Subscription plan created successfully',
            data: plan
        });
    } catch (error) {
        console.error('Error creating subscription plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create subscription plan',
            error: error.message
        });
    }
});

// Update subscription plan
router.put('/plans/:id', async (req, res) => {
    try {
        const {
            planId,
            name,
            description,
            frequency,
            discountPercentage,
            minCommitmentMonths,
            benefits,
            isActive,
            sortOrder
        } = req.body;
        
        // Find the plan
        const plan = await SubscriptionPlan.findById(req.params.id);
        
        if (!plan) {
            return res.status(404).json({
                success: false,
                message: 'Subscription plan not found'
            });
        }
        
        // If planId is being changed, check it's not already used
        if (planId && planId !== plan.planId) {
            const existingPlan = await SubscriptionPlan.findOne({ planId });
            if (existingPlan) {
                return res.status(400).json({
                    success: false,
                    message: 'A plan with this Plan ID already exists'
                });
            }
            plan.planId = planId;
        }
        
        // Update fields
        if (name !== undefined) plan.name = name;
        if (description !== undefined) plan.description = description;
        if (frequency !== undefined) plan.frequency = frequency;
        if (discountPercentage !== undefined) plan.discountPercentage = discountPercentage;
        if (minCommitmentMonths !== undefined) plan.minCommitmentMonths = minCommitmentMonths;
        if (benefits !== undefined) plan.benefits = benefits;
        if (isActive !== undefined) plan.isActive = isActive;
        if (sortOrder !== undefined) plan.sortOrder = sortOrder;
        
        await plan.save();
        
        res.json({
            success: true,
            message: 'Subscription plan updated successfully',
            data: plan
        });
    } catch (error) {
        console.error('Error updating subscription plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update subscription plan',
            error: error.message
        });
    }
});

// Delete subscription plan
router.delete('/plans/:id', async (req, res) => {
    try {
        const plan = await SubscriptionPlan.findById(req.params.id);
        
        if (!plan) {
            return res.status(404).json({
                success: false,
                message: 'Subscription plan not found'
            });
        }
        
        // Check if plan is being used in active subscriptions
        const activeSubscriptions = await Subscription.countDocuments({
            planId: plan.planId,
            status: 'active'
        });
        
        if (activeSubscriptions > 0) {
            return res.status(400).json({
                success: false,
                message: `Cannot delete plan. It is currently used by ${activeSubscriptions} active subscription(s). Consider deactivating it instead.`
            });
        }
        
        await SubscriptionPlan.findByIdAndDelete(req.params.id);
        
        res.json({
            success: true,
            message: 'Subscription plan deleted successfully'
        });
    } catch (error) {
        console.error('Error deleting subscription plan:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete subscription plan',
            error: error.message
        });
    }
});

module.exports = router;

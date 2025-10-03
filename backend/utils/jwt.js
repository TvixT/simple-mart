const jwt = require('jsonwebtoken');

// JWT utility functions
class JWTUtils {
  // Generate JWT token
  static generateToken(payload, expiresIn = '24h') {
    return jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn,
      issuer: 'simple_mart',
      audience: 'simple_mart_users'
    });
  }

  // Verify JWT token
  static verifyToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET, {
        issuer: 'simple_mart',
        audience: 'simple_mart_users'
      });
    } catch (error) {
      throw new Error('Invalid or expired token');
    }
  }

  // Generate refresh token (longer expiry)
  static generateRefreshToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: '7d',
      issuer: 'simple_mart',
      audience: 'simple_mart_refresh'
    });
  }

  // Verify refresh token
  static verifyRefreshToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET, {
        issuer: 'simple_mart',
        audience: 'simple_mart_refresh'
      });
    } catch (error) {
      throw new Error('Invalid or expired refresh token');
    }
  }

  // Extract token from Authorization header
  static extractTokenFromHeader(authHeader) {
    if (!authHeader) {
      return null;
    }

    const parts = authHeader.split(' ');
    if (parts.length === 2 && parts[0] === 'Bearer') {
      return parts[1];
    }

    return null;
  }
}

module.exports = JWTUtils;
import React from 'react';
import './Footer.css';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="row">
          <div className="col-md-4">
            <h5>Address</h5>
            <p>123 Main St, Anytown, USA 12345</p>
          </div>
          <div className="col-md-4">
            <h5>Phone</h5>
            <p>(123) 456-7890</p>
          </div>
          <div className="col-md-4">
            <h5>Email</h5>
            <p><a href="mailto:info@example.com">info@example.com</a></p>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
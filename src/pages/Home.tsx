import React from 'react';
import Card1 from '../components/Card1';
import Card2 from '../components/Card2';
import Card3 from '../components/Card3';

function Home() {
  return (
    <div className="home">
      <h1>Custom Cards</h1>
      <div className="card-container">
        <Card1 />
        <Card2 />
        <Card3 />
      </div>
    </div>
  );
}

export default Home;
import pytest
from app.main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_endpoint(client):
    """Test endpoint principal"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert data['application'] == 'Python CI/CD Demo'
    assert 'server_time' in data
    assert 'status' in data

def test_health_endpoint(client):
    """Test health check"""
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] in ['healthy', 'unhealthy']
    assert 'system_metrics' in data

def test_status_endpoint(client):
    """Test status endpoint"""
    response = client.get('/status')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'ok'
    assert data['code'] == 200
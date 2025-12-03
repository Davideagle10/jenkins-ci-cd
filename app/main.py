"""
Servidor Web Python Minimalista para CI/CD
"""
from flask import Flask, jsonify
import datetime
import socket
import platform
import os
import psutil

app = Flask(__name__)

@app.route('/')
def index():
    """Endpoint principal - Información del sistema"""
    return jsonify({
        'application': 'Python CI/CD Demo',
        'version': '1.0.0',
        'status': 'operational',
        'server_time': datetime.datetime.now().isoformat(),
        'host': socket.gethostname(),
        'python': platform.python_version(),
        'environment': os.getenv('ENV', 'production')
    })

@app.route('/health')
def health():
    """Health check real - Estado del servidor"""
    try:
        # Métricas reales del sistema
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.datetime.now().isoformat(),
            'system_metrics': {
                'cpu_usage_percent': cpu_percent,
                'memory_available_gb': round(memory.available / (1024**3), 2),
                'memory_used_percent': memory.percent,
                'disk_free_gb': round(disk.free / (1024**3), 2),
                'disk_used_percent': disk.percent
            },
            'application': {
                'uptime': 'running',
                'endpoints_available': ['/', '/health', '/status']
            }
        })
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.datetime.now().isoformat()
        }), 500

@app.route('/status')
def status():
    """Endpoint de estado simple"""
    return jsonify({
        'status': 'ok',
        'code': 200,
        'message': 'Service is running normally'
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
# Imagen base oficial Python
FROM python:3.9-slim

# Directorio de trabajo
WORKDIR /app

# Instalar solo curl para health checks
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Copiar dependencias e instalar
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar aplicación
COPY . .

# Puerto de la aplicación
ENV PORT=5000

# Health check real
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
CMD curl -f http://localhost:5000/health || exit 1

# Exponer puerto
EXPOSE 5000

# Ejecutar con gunicorn (production-ready)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app.main:app"]
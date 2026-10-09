import numpy as np
import matplotlib.pyplot as plt

# Load the div(u) L2 norm data from the text file
div_norms = np.loadtxt("w5_div_norms_pure.txt")
div_norms_sflt = np.loadtxt("w5_div_norms_SFLT.txt")

# Create the plot
plt.rcParams.update({'font.size': 14})
plt.figure(figsize=(10, 6))

plt.plot(div_norms, 'b-', linewidth=2, label='Deterministic')
plt.plot(div_norms_sflt, 'r-', linewidth=2, label='Stochastic')

plt.xlabel('Time steps')
plt.ylabel(r'$\|\nabla\cdot u\|_{L^2}$')
plt.title('Divergence of velocity vs Time')
plt.legend()
plt.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig("w5_div_norms.png", dpi=150)
plt.show()

# Print some statistics
print(f"Data shape: {div_norms.shape}")
print(f"Total points: {len(div_norms)}")
print(f"Min norm: {np.min(div_norms):.6e}")
print(f"Max norm: {np.max(div_norms):.6e}")
print(f"Mean norm: {np.mean(div_norms):.6e}")
print(f"Final norm: {div_norms[-1]:.6e}")
